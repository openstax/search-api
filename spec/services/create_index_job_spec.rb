require 'rails_helper'

RSpec.describe CreateIndexJob do
  let(:body) {
    {
      type: "CreateIndexJob",
      book_version_id: "foo@1",
      indexing_strategy_name: "I1",
      status: { status: "successful" },
      es_stats: { num_docs_in_index: 7000 },
      time_took: '00:05:00'
    }
  }
  subject(:create_index_job) { described_class.build_object(body: body, cleanup_after_call: nil) }

  describe '#call' do
    it "recreates the index" do
      expect_any_instance_of(Search::BookVersions::Index).to receive(:recreate).once

      create_index_job.call
    end
  end

  describe '#as_json' do
    it 'converts to json' do
      expect(create_index_job.to_json).to include_json(
                                            type: 'CreateIndexJob',
                                            book_version_id: 'foo@1',
                                            indexing_strategy_name: "I1")
    end
  end
end
