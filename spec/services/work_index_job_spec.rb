require 'rails_helper'

RSpec.describe WorkIndexJob do
  subject(:work_index_job) { described_class.new }

  let(:indexing_version) { 'I1' }
  let(:job_body) {
    {
      book_version_id: 'foo',
      indexing_version: indexing_version
    }
  }
  let(:create_job) { CreateIndexJob.build_object(body: job_body, when_completed_proc: nil) }
  let(:delete_job) { DeleteIndexJob.build_object(body: job_body, when_completed_proc: nil) }

  describe '#out_of_work?' do
    before do
      allow_any_instance_of(DoneJobsQueue).to receive(:write)
    end

    it 'signals correct out of work or not out of work' do
      expect(work_index_job.fuzzy_check_out_of_work?).to be_falsey

      allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(nil)
      work_index_job.call
      expect(work_index_job.fuzzy_check_out_of_work?).to be_truthy

      allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(create_job)
      work_index_job.call
      expect(work_index_job.fuzzy_check_out_of_work?).to be_falsey
    end
  end

  describe '#call' do
    context 'todo queue has a create index job' do
      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(create_job)
      end

      it 'calls to create elasticsearch index & then adds to done queue' do
        expect_any_instance_of(CreateIndexJob).to receive(:call).once
        expect_any_instance_of(DoneJobsQueue).to receive(:write).once
        work_index_job.call
      end
    end

    context 'todo queue has a delete index job' do
      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(delete_job)
      end

      it 'calls to delete elasticsearch index & then adds to done queue' do
        expect_any_instance_of(DeleteIndexJob).to receive(:call).once
        expect_any_instance_of(DoneJobsQueue).to receive(:write).once
        work_index_job.call
      end
    end

    context 'the job has an invalid indexing version' do
      let(:indexing_version) { 'invalid' }

      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(create_job)
      end

      it 'doesnt call createindexjob & adds to the done queue' do
        expect_any_instance_of(CreateIndexJob).to_not receive(:call)
        expect_any_instance_of(DoneJobsQueue).to receive(:write).once
        work_index_job.call
      end
    end
  end
end



