require 'rails_helper'

RSpec.describe MonitorIndexJobs do
  subject(:monitor_index_jobs) { described_class.new }

  describe '#call' do
    let(:create_job) { CreateIndexJob.new }
    let(:delete_job) { DeleteIndexJob.new }

    context 'create and delete jobs present in the done jobs queue' do
      before do
        allow_any_instance_of(DoneJobsQueue).to receive(:read).and_return(create_job, delete_job, nil)
        allow_any_instance_of(DeadLetterJobsQueue).to receive(:read).and_return(nil)
        allow_any_instance_of(TodoJobsQueue).to receive(:count).and_return(0)
        allow_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:increase_desired_capacity)
      end

      it 'calls to any jobs in the queue' do
        expect_any_instance_of(CreateIndexJob).to receive(:call).once
        expect_any_instance_of(DeleteIndexJob).to receive(:call).once
        monitor_index_jobs.call
      end
    end

    context 'non-empty dead queue' do
      let(:book_index_state) { double(to_hash: {}) }

      before do
        allow_any_instance_of(DeadLetterJobsQueue).to receive(:read).and_return(create_job, nil)
        allow_any_instance_of(DoneJobsQueue).to receive(:read).and_return(nil)
        allow_any_instance_of(TodoJobsQueue).to receive(:count).and_return(0)
        allow_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:increase_desired_capacity)
        allow_any_instance_of(BaseIndexJob).to receive(:find_associated_book_index_state).and_return(book_index_state)
      end

      it 'sends a message to Sentry for any job in the dead queue' do
        expect(Raven).to receive(:capture_message).once
        monitor_index_jobs.call
      end
    end

    context 'desired capacity needs adjusting' do
      before do
        allow_any_instance_of(TodoJobsQueue).to receive(:count).and_return(2)
        expect_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:desired_capacity).and_return(0)
        allow_any_instance_of(DoneJobsQueue).to receive(:read).and_return(nil)
        allow_any_instance_of(DeadLetterJobsQueue).to receive(:read).and_return(nil)

        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'sends a message to aws autoscalinggroup to increase desired capacity' do
        expect_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:increase_desired_capacity).with(by: 2)
        monitor_index_jobs.call
      end
    end
  end
end
