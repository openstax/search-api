require 'rails_helper'
require 'vcr_helper'

# A BookIndexing model is the ORM to the AWS dynamo db.  This table records
# book indexing jobs enqueuing, starting, and finishing.
RSpec.describe BookIndexing, vcr: VCR_OPTS do
  let(:book_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:indexing_version) { 'I1' }

  subject(:book_indexing) { described_class }

  describe ".create" do
    it 'creates the a document row in the dynamo db table' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_tables

        book_indexing.create(book_version_id: book_id, indexing_version: indexing_version)
        expect(BookIndexing.where(book_version_id: book_id).count).to eq 1
      end
    end

    it 'creates only one document for a started book indexing job' do
      TempAwsEnv.make do |env|
        env.create_dynamodb_tables

        book_indexing.create(book_version_id: book_id, indexing_version: indexing_version)
        expect{
          book_indexing.create(book_version_id: book_id, indexing_version: indexing_version)
        }.to raise_error(Dynamoid::Errors::DocumentNotValid)

        expect(BookIndexing.where(book_version_id: book_id).count).to eq 1
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
