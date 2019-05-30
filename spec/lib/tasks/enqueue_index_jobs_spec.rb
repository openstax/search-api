require 'rails_helper'

RSpec.describe "enqueue_index_jobs", type: :rake do
  include_context "rake"

  let(:num_create_index_jobs) { 3 }
  let(:num_delete_index_jobs) { 2 }

  before {
    allow_any_instance_of(EnqueueIndexJobs).to receive(:call) {{
        num_delete_index_jobs: num_delete_index_jobs,
        num_create_index_jobs: num_create_index_jobs
    }}
  }

  it "increments worker ASG capacity" do
    expect_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:increase_desired_capacity).with(by: 5)
    call
  end
end
