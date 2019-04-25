require 'rails_helper'
require 'vcr_helper'

RSpec.describe EnqueueIndexJobs, vcr: VCR_OPTS do
  let(:indexing_version) { 'I1' }
  let(:book_ids) {%w(foo@1 foo@2)}
  let(:book1_to_index) { double(book_version_id: 'foo@1', in_demand: true, indexing_version: 'i1') }
  let(:book2_to_index) { double(book_version_id: 'foo@2', in_demand: true, indexing_version: 'i1') }

  subject(:enqueue_index_job) { described_class.new }

  context "new book listings" do
    let(:book1_to_index) { double(book_version_id: 'foo@1', in_demand: true, indexing_version: 'i1') }
    let(:book2_to_index) { double(book_version_id: 'foo@2', in_demand: true, indexing_version: 'i1') }

    before do
      allow_any_instance_of(OpenStax::RexReleases).to receive(:map).and_return(book_ids)
      allow_any_instance_of(OpenStax::RexReleases).to receive(:load_releases)
      allow_any_instance_of(TodoJobsQueue).to receive(:count).and_return(2)
      allow(BookIndexing).to receive(:live_book_indexings).and_return([book1_to_index, book2_to_index])
    end

    describe "#call" do
      it 'sends expected messages to the BookIndexing, TodoJobsQueue, and asg objects' do
        expect(BookIndexing).to receive(:create_new_indexing).twice

        todo_jobs_receive_count = 0
        allow_any_instance_of(TodoJobsQueue).to receive(:write) { todo_jobs_receive_count += 1 }
        asg_receive_count = 0
        allow_any_instance_of(AutoScalingGroup).to receive(:increase_desired_capacity) { asg_receive_count += 1 }

        enqueue_index_job.call

        expect(todo_jobs_receive_count).to eq 2
        expect(asg_receive_count).to eq 1
      end
    end
  end

  context "enqueued book listings not existing in rex releases" do
    let(:released_book_ids) {%w(foo@1)}
    let(:book1_to_index) { double(book_version_id: 'foo@1', in_demand: true, indexing_version: 'i1') }
    let(:now_inactive_book) { double(book_version_id: 'foo@2', in_demand: false, indexing_version: 'i1', queue_to_delete: nil) }

    before do
      allow_any_instance_of(OpenStax::RexReleases).to receive(:map).and_return(released_book_ids)
      allow_any_instance_of(OpenStax::RexReleases).to receive(:load_releases)
      allow_any_instance_of(TodoJobsQueue).to receive(:count).and_return(2)
      allow(BookIndexing).to receive(:live_book_indexings).and_return([book1_to_index, now_inactive_book])
    end

    describe "#call" do
      it 'enqueues one delete job, one index job and updates the auto scaling group by this amount' do
        expect(BookIndexing).to receive(:create_new_indexing).once

        expect_any_instance_of(TodoJobsQueue).to receive(:write).with(instance_of(DeleteIndexJob)).once
        expect_any_instance_of(TodoJobsQueue).to receive(:write).with(instance_of(CreateIndexJob)).once
        expect_any_instance_of(AutoScalingGroup).to receive(:increase_desired_capacity).with(by: 2).once

        enqueue_index_job.call
      end
    end
  end
end

