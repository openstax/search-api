require 'rails_helper'

RSpec.describe DoneIndexJob do
  let(:ran_created_job) { CreateIndexJob.new(book_version_id: "foo@1",
                                         indexing_strategy_name: "I1")}
  let(:status) { "successful" }
  let(:body) {
    {
      type: "DoneIndexJob",
      status: status,
      book_version_id: "foo@1",
      ran_job: ran_created_job.to_hash,
      indexing_strategy_name: "I1"
    }
  }
  subject(:done_index_job) { described_class.build_object(params: body, cleanup_after_call: nil) }

  describe '#call' do
    let(:book_index_state) { double(to_hash: {foo: 1}) }

    before do
      allow(done_index_job).to receive(:find_associated_book_index_state).and_return(book_index_state)
    end

    context 'when successful' do
      it 'calls cleanup' do
        expect_any_instance_of(CreateIndexJob).to receive(:cleanup_when_done)
        done_index_job.call
      end
    end

    context 'when not successful' do
      let(:status) { "failed" }

      it 'sends a message to Raven and removes the associated book index state' do
        expect(Raven).to receive(:capture_message)
        expect_any_instance_of(CreateIndexJob).to receive(:remove_associated_book_index_state)

        done_index_job.call
      end
    end
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
