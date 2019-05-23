require 'rails_helper'

RSpec.describe DeleteIndexJob do
  let(:body) {
    {
      type: "DeleteIndexJob",
      book_version_id: "foo@1",
      indexing_strategy_name: "I1"
    }
  }
  subject(:delete_index_job) { described_class.build_object(body: body, cleanup_after_call: nil) }

  describe '#call' do
    it "calls to delete the index" do
      expect_any_instance_of(Search::BookVersions::Index).to receive(:delete).once

      delete_index_job.call
    end
  end

  describe '#as_json' do
    it 'converts to json' do
      expect(delete_index_job.as_json).to include_json(
                                            type: 'DeleteIndexJob',
                                            book_version_id: 'foo@1')
    end
  end
end
