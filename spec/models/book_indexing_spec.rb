require 'rails_helper'
require 'vcr_helper'

# A BookIndexing model is the ORM to the AWS dynamo db.  This table records
# book indexing jobs enqueuing, starting, and finishing.
RSpec.describe BookIndexing, vcr: VCR_OPTS do
  let(:book_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:indexing_version) { 'I1' }

  subject(:book_indexing) { described_class }

  describe ".create_new_indexing" do
    it 'creates the a document row in the dynamo db table' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table

        book_indexing.create_new_indexing(book_version_id: book_id, indexing_version: indexing_version)
        expect(BookIndexing.where(book_version_id: book_id).count).to eq 1
      end
    end
  end

  describe ".live_book_indexings" do
    let(:book_id1) { 'book@1'}
    let(:book_id2) { 'book@2'}
    let(:book_id3) { 'book@3'}

    def init_test
      book_indexing.new(state: BookIndexing::STATE_PENDING,
                        book_version_id: book_id1,
                        indexing_version: indexing_version,
                        message: 'message 1').save!
      book_indexing.new(state: BookIndexing::STATE_DELETE_PENDING,
                        book_version_id: book_id2,
                        indexing_version: indexing_version,
                        message: 'message 2').save!
      book_indexing.new(state: BookIndexing::STATE_DELETED,
                        book_version_id: book_id3,
                        indexing_version: indexing_version,
                        message: 'message 3').save!
    end

    it 'finds only live documents, not the deleting ones' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table
        init_test

        expect(BookIndexing.all.count).to eq 3   # BookIndexing.count doesnt work
        expect(BookIndexing.live_book_indexings.count).to eq 1
      end
    end
  end

  describe "#queue_to_delete" do
    let(:live_indexing) do
      book_indexing.create_new_indexing(book_version_id: book_id, indexing_version: indexing_version)
    end

    it 'updates the document to be deleted' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_table

        expect(live_indexing.state).to eq BookIndexing::STATE_PENDING
        live_indexing.queue_to_delete
        expect(live_indexing.state).to eq BookIndexing::STATE_DELETE_PENDING
      end
    end
  end

  describe "#start" do
    it 'starts the a document row in the dynamo db table' do
      # TODO
    end
  end

  describe ".finish" do
    it 'finishes the a document row in the dynamo db table' do
      # TODO
    end
  end
end
