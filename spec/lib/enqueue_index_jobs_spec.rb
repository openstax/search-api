require 'rails_helper'

RSpec.describe 'enqueue_index_jobs', type: :rake do
  include_context 'rake'

  it 'sends a message to the enqueueindexJobs to process the rex release' do
    expect_any_instance_of(EnqueueIndexJobs).to receive(:process_rex_releases)
    call
  end
end
