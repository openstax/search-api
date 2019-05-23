require 'rails_helper'

RSpec.describe DoneIndexJob do
  let(:created_job) { CreateIndexJob.new(book_version_id: "foo@1",
                                         indexing_strategy_name: "I1")}
  let(:body) {
    {
      type: "DoneIndexJob",
      status: "successful",
      book_version_id: "foo@1",
      ran_job: created_job.to_json,
      indexing_strategy_name: "I1"
    }
  }
  subject(:done_index_job) { described_class.build_object(params: body, cleanup_after_call: nil) }

  xdescribe '#call' do
  end

  describe '#as_json' do
    it 'has the high level attributes' do
      expect(done_index_job.to_json).to include_json(
                                            type: 'DoneIndexJob',
                                            status: 'successful' )
    end

    it 'has the nested ran job in json form' do
      expect(done_index_job.to_json).to include_json(
                                          ran_job: {
                                            type: 'CreateIndexJob',
                                            book_version_id: 'foo@1',
                                            indexing_strategy_name: 'I1'
                                          })
      expect(done_index_job.ran_job).to be_kind_of(CreateIndexJob)
    end

    it 'rehydrates the nested ran job as an object' do
      expect(done_index_job.ran_job).to be_kind_of(CreateIndexJob)
    end
  end
end
