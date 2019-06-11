require 'rails_helper'
require 'vcr_helper'

require 'rex/rex_releases'

RSpec.describe BaseQueue, vcr: VCR_OPTS do
  let(:indexing_strategy_name) { "I1" }
  let(:book_version_id) { "foo@1" }
  let(:job_data) { CreateIndexJob.new(book_version_id: book_version_id, indexing_strategy_name: indexing_strategy_name) }

  describe "#write" do
    it 'writes a item in a queue' do
      TempAwsEnv.make do |env|
        env.create_sqs(name: "one")
        todo_queue = described_class.new(url: env.sqs_queue_url)
        todo_queue.write job_data

        expect(todo_queue.count).to eq 1
      end
    end
  end

  describe "#read" do
    it 'reads an item from a queue' do
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
end
