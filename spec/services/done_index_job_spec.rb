require 'rails_helper'

RSpec.describe DoneIndexJob do
  let(:results) { DoneIndexJob::Results.new }

  let(:body) {
    {
      type: "DoneIndexJob",
      book_version_id: "foo@1",
      results: results,
      indexing_strategy_name: "I1"
    }
  }
  subject(:done_index_job) { described_class.build_object(body: body, when_completed_proc: nil) }

  xdescribe '#call' do
  end

  describe '#as_json' do
    it 'converts to json' do
      expect(done_index_job.to_json).to include_json(
                                            type: 'DoneIndexJob',
                                            book_version_id: 'foo@1',
                                            results: {
                                              status: 'successful'
                                            })
    end
  end
end
