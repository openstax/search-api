require 'rails_helper'
require 'vcr_helper'

require 'openstax/rex_releases'

RSpec.describe DoneJobsQueue, vcr: VCR_OPTS do
  let(:indexing_strategy_name) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:job_data) { DoneIndexJob.new }

  it 'writes a done job in the done jobs queue' do
    TempAwsEnv.make do |env|
      env.create_sqs
      done_queue = described_class.new(url: env.sqs_queue_url)
      done_queue.write job_data

      expect(done_queue.count).to eq 1
    end
  end
end
