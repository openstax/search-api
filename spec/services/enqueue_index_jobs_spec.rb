require 'rails_helper'
require 'vcr_helper'

RSpec.describe EnqueueIndexJobs, vcr: VCR_OPTS do
  let(:indexing_version) { 'I1' }
  let(:book_ids) {%w(abc@1 foo@2)}

  subject(:enqueue_index_job) { described_class.new(indexing_version: indexing_version) }

  before do
    allow_any_instance_of(OpenStax::RexReleases).to receive(:map).and_return(book_ids)
    allow_any_instance_of(OpenStax::RexReleases).to receive(:load_releases)
    allow(TodoJobsQueue).to receive(:size).and_return(2)
  end

  describe "#process_rex_releases" do
    it 'sends expected messages to the BookIndexing and TodoJobsQueue objects' do
      expect(AutoScaling).to receive(:set_desired_capacity).twice
      expect(BookIndexing).to receive(:create).twice
      receive_count = 0
      allow_any_instance_of(TodoJobsQueue).to receive(:write) { receive_count += 1 }

      enqueue_index_job.process_rex_releases

      expect(receive_count).to eq 2
    end
  end
end

