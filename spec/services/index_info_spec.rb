require 'rails_helper'
require 'vcr_helper'

RSpec.describe IndexInfo, vcr: VCR_OPTS do
  let(:book_version_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:index) { Books::Index.new(book_version_id: book_version_id) }
  let(:indexing_strategy) { "I1" }
  let(:book_index_name) { "#{book_version_id}_#{indexing_strategy}".downcase }

  before(:each) do
    do_not_record_or_playback do
      if !index.exists?
        index.create
        index.populate
      end
    end
  end

  subject(:info_service) { described_class.new }

  describe "#call" do
    context "elasticsearch and dynamodb records both exist" do
      it "gets the info" do
        TempAwsEnv.make do |env|
          env.create_dynamodb_table
          BookIndexState.create(book_version_id:  book_version_id,
                                indexing_strategy_name: indexing_strategy)

          info = info_service.call

          expect(info[:book_indexes].first).to match(hash_including({id: book_index_name}))
          expect(info[:book_indexes].first).to match(hash_including({state: "create pending"}))
        end
      end
    end

    context "elasticsearch exists but not a dynamodb" do
      it "gets the info" do
        TempAwsEnv.make do |env|
          env.create_dynamodb_table

          info = info_service.call

          expect(info[:book_indexes].first).to match(hash_including({id: book_index_name}))
          expect(info[:book_indexes].first).to match(hash_including({state: "not found"}))
        end
      end
    end
  end
end
