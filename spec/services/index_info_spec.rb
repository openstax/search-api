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
    let(:iso8601_regex) {
      /^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\\.[0-9]+)?(Z)?$/
    }

    context "elasticsearch and dynamodb records both exist" do
      it "gets the info" do
        TempAwsEnv.make do |env|
          env.create_dynamodb_table
          BookIndexState.create(book_version_id:  book_version_id,
                                indexing_strategy_name: indexing_strategy)

          info = info_service.call

          book_info = info[:book_indexes].detect{|index| index[:id] == book_index_name}
          expect(book_info[:state]).to eq 'create pending'
          expect(book_info[:created_at]).to match iso8601_regex
        end
      end
    end

    context "elasticsearch exists but not a dynamodb" do
      it "gets the info" do
        TempAwsEnv.make do |env|
          env.create_dynamodb_table

          info = info_service.call

          book_info = info[:book_indexes].detect{|index| index[:id] == book_index_name}
          expect(book_info[:state]).to eq 'not found'
          expect(book_info[:created_at]).to match iso8601_regex
        end
      end
    end
  end
end
