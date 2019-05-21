require 'rails_helper'
require 'vcr_helper'

amazon_api_header_matcher = lambda do |request_1, request_2|
  request_1.headers["X-Amz-Target"] == request_2.headers["X-Amz-Target"]
end

# A BookIndexState model is the ORM to the AWS dynamo db.  This table records
# book indexing jobs enqueuing, starting, and finishing.
RSpec.describe BookIndexState, vcr: VCR_OPTS.merge!({match_requests_on: [:method, :uri, amazon_api_header_matcher]}) do
  let(:book_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:indexing_strategy_name) { 'I1' }

  subject(:book_index_state) { described_class }

  describe ".create" do
    it 'creates a document item in the dynamo db table with correct status' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table

        book = book_index_state.create(book_version_id: book_id, indexing_strategy_name: indexing_strategy_name)
        created_book_arel = BookIndexState.where(book_version_id: book_id)
        expect(created_book_arel.count).to eq 1

        book_status_log = book.status_log
        expect(book_status_log.count).to eq 1
        expect(book_status_log.first.action).to eq BookIndexState::Status::ACTION_CREATE
      end
    end
  end

  describe ".live_book_indexings" do
    let(:book_id1) { 'book@1' }
    let(:book_id2) { 'book@2' }
    let(:book_id3) { 'book@3' }

    def init_test
      book_index_state.new(state: BookIndexState::STATE_CREATE_PENDING,
                           book_version_id: book_id1,
                           indexing_strategy_name: indexing_strategy_name,
                           message: 'message 1').save!
      book_index_state.new(state: BookIndexState::STATE_DELETE_PENDING,
                           book_version_id: book_id2,
                           indexing_strategy_name: indexing_strategy_name,
                           message: 'message 2').save!
      book_index_state.new(state: BookIndexState::STATE_DELETED,
                           book_version_id: book_id3,
                           indexing_strategy_name: indexing_strategy_name,
                           message: 'message 3').save!
    end

    it 'finds only live documents, not the deleting ones' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table
        init_test

        expect(BookIndexState.all.count).to eq 3   # BookIndexState.count doesnt work
        expect(BookIndexState.live.count).to eq 1
      end
    end
  end

  describe "#mark_queued_for_deletion" do
    let(:live_indexing) do
      book_index_state.create(book_version_id: book_id, indexing_strategy_name: indexing_strategy_name)
    end

    it 'updates the document to be deleted' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table

        expect(live_indexing.state).to eq BookIndexState::STATE_CREATE_PENDING
        live_indexing.mark_queued_for_deletion
        expect(live_indexing.state).to eq BookIndexState::STATE_DELETE_PENDING
      end
    end
  end
end
