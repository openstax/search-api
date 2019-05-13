require 'rails_helper'
require 'vcr_helper'

require 'openstax/rex_releases'

RSpec.describe DoneJobsQueue, vcr: VCR_OPTS do
  let(:indexing_version) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:done_job_results) { DoneIndexJob::Results::STATUS_SUCCESSFUL }
  let(:job_data) {
    DoneIndexJob.new(results: done_job_results,
                     book_version_id: book_version_id, indexing_version: indexing_version)
  }

  it 'writes a done job in the done jobs queue' do
    TempAwsEnv.make do |env|
      env.create_sqs
      done_queue = described_class.new(url: env.sqs_queue_url)
      done_queue.write job_data

      expect(done_queue.count).to eq 1
    end
  end
end
