require 'rails_helper'
require 'vcr_helper'

require 'openstax/rex_releases'

RSpec.describe TodoJobsQueue, vcr: VCR_OPTS do
  let(:indexing_version) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:job_data) { CreateIndexJob.new(book_version_id: book_version_id, indexing_version: indexing_version) }

  it 'writes a todo item in the todo queue' do
    TempAwsEnv.make do |env|
      env.create_sqs(name: "one")
      todo_queue = described_class.new(url: env.sqs_queue_url)
      todo_queue.write job_data

      expect(todo_queue.count).to eq 1
    end
  end

  it 'reads a todo item from the todo queue' do
    TempAwsEnv.make do |env|
      env.create_sqs(name: "two")
      todo_queue = described_class.new(url: env.sqs_queue_url)
      todo_queue.write job_data
      read_job_data = todo_queue.read

      expect(read_job_data).to be_a(CreateIndexJob)
      expect(read_job_data.book_version_id).to eq job_data.book_version_id
    end
  end
end
