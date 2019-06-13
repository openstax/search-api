require 'rails_helper'

RSpec.describe "enqueue_index_jobs", type: :rake do
  include_context "rake"

  let(:num_create_index_jobs) { 3 }
  let(:num_delete_index_jobs) { 2 }
  let(:auto_scaling_instance) {
    OpenStax::Aws::AutoScalingInstance.new(group_name: "foo", id: "bar", region: "us-east-2")
  }

  before {
    allow_any_instance_of(EnqueueIndexJobs).to receive(:call) {{
        num_delete_index_jobs: num_delete_index_jobs,
        num_create_index_jobs: num_create_index_jobs
    }}

    allow(OpenStax::Aws::AutoScalingInstance).to receive(:me) { auto_scaling_instance }
    allow(auto_scaling_instance).to receive(:terminating_wait?) { false }
  }

  it "increments worker ASG capacity" do
    expect_any_instance_of(OpenStax::Aws::AutoScalingGroup).to receive(:increase_desired_capacity).with(by: 5)
    call
  end
end
