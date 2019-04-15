require 'rails_helper'
require 'vcr_helper'

require 'openstax/rex_releases'

RSpec.describe TodoJobsQueue, vcr: VCR_OPTS do
  let(:indexing_version) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:job_data) { IndexingJob.new(book_version_id: book_version_id, indexing_version: indexing_version) }

  it 'reads the release IDs from S3' do
    TempAwsEnv.make do |env|
      env.create_sqs
      todo_queue = described_class.new(url: env.sqs_queue_url)
      todo_queue.write job_data

      expect(todo_queue.count).to eq 1
    end
  end
end
