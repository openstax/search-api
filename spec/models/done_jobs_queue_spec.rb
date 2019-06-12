require 'rails_helper'

require 'rex/rex_releases'

RSpec.describe DoneJobsQueue do
  let(:indexing_strategy_name) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:job_data) { DoneIndexJob.new }

  it 'writes a done job in the done jobs queue' do
    done_queue = described_class.new(url: "foo_url")
    expect(done_queue).to be_a_kind_of(DoneJobsQueue)
  end
end
