require 'rails_helper'

RSpec.describe WorkIndexJobs do
  subject(:work_index_jobs) { described_class.new }

  let(:indexing_strategy_name) { 'I1' }
  let(:job_body) {
    {
      book_version_id: 'foo',
      indexing_strategy_name: indexing_strategy_name
    }
  }
  let(:create_job) { CreateIndexJob.build_object(params: job_body, cleanup_after_call: nil) }
  let(:delete_job) { DeleteIndexJob.build_object(params: job_body, cleanup_after_call: nil) }

  describe '#out_of_work?' do
    before do
      allow_any_instance_of(DoneJobsQueue).to receive(:write)
      allow(create_job).to receive(:_call)
    end

    it 'signals correct out of work or not out of work' do
      expect(work_index_jobs.definitely_out_of_work?).to be_falsey

      allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(nil)
      work_index_jobs.call
      expect(work_index_jobs.definitely_out_of_work?).to be_truthy

      allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(create_job)
      work_index_jobs.call
      expect(work_index_jobs.definitely_out_of_work?).to be_falsey
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
        work_index_jobs.call
      end
    end

    context 'todo queue has a delete index job' do
      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(delete_job)
      end

      it 'calls to delete elasticsearch index & then adds to done queue' do
        expect_any_instance_of(DeleteIndexJob).to receive(:call).once
        expect_any_instance_of(DoneJobsQueue).to receive(:write).once
        work_index_jobs.call
      end
    end

    context 'miscellaneous errors' do
      let(:job_with_exception) {
        class FooJob
          def call
            1/0
          end
        end
        FooJob.new
      }

      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(job_with_exception)
      end

      it 'calls handle error with correct status' do
        expect_any_instance_of(described_class)
          .to receive(:handle_error)
                .with(exception: anything, job: anything, status: DoneIndexJob::STATUS_OTHER_ERROR)
        expect {
          work_index_jobs.call
        }.to_not raise_error(Exception)
      end
    end

    context 'http errors' do
      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:read).and_return(create_job)

        allow(create_job).to receive(:inspect)
        allow_any_instance_of(Books::Index).to receive(:delete)
        allow_any_instance_of(Books::Index).to receive(:create)
      end

      context 'the job raises a 404 error' do
        before do
          stub_request(:get, /archive.cnx.org/).to_return(status: 404, headers: {})
        end

        it 'calls handle error with correct status' do
          expect_any_instance_of(described_class)
            .to receive(:handle_error)
                  .with(exception: anything, job: anything, status: DoneIndexJob::STATUS_HTTP_404_ERROR)

          work_index_jobs.call
        end
      end

      context 'the job raises a 5xx' do
        before do
          stub_request(:get, /archive.cnx.org/).to_return(status: 503, headers: {})
        end

        it 'calls handle error with correct status' do
          expect_any_instance_of(described_class)
            .to receive(:handle_error)
                  .with(exception: anything, job: anything, status: DoneIndexJob::STATUS_HTTP_5XX_ERROR)

          work_index_jobs.call
        end
      end

      context 'the job raises a http other error (other than 404 and 5xx http errors' do
        before do
          # raise a 403 forbidden error
          stub_request(:get, /archive.cnx.org/).to_return(status: 403 , headers: {})
        end

        it 'calls handle error with correct status' do
          expect_any_instance_of(described_class)
            .to receive(:handle_error)
                  .with(exception: anything, job: anything, status: DoneIndexJob::STATUS_HTTP_OTHER_ERROR)

          work_index_jobs.call
        end
      end
    end
  end
end
