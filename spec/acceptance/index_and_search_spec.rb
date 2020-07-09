require 'rails_helper'
require 'vcr_helper'

amazon_api_header_matcher = lambda do |request_1, request_2|
  request_1.headers["X-Amz-Target"] == request_2.headers["X-Amz-Target"]
end

# This test expects authentication to a AWS account and ElasticSearch running on
# port 4003.
#
# The test creates the AWS env (dynamodb table, and 3 SQS queues).  It then
# simulates what the cron jobs would do going thru normal indexing for 2 books.
# It will assert that the indexes are created and search is successful. Checks for
# happy path processing for 2 major use cases: normal indexing and removed indexing
RSpec.describe 'Acceptance', type: :acceptance, api: :v0, vcr: VCR_OPTS.merge!({match_requests_on: [:method, :uri, amazon_api_header_matcher]}) do
  let(:book1_id) { "02040312-72c8-441e-a685-20e9333f3e1d" }
  let(:book1_version) { "12.6" }
  let(:book2_id) { "914ac66e-e1ec-486d-8a9c-97b0f7a99774" }
  let(:book2_version) { "4.1" }
  let(:book_1_version_id) { %W(#{book1_id}@#{book1_version}) }
  let(:book_2_version_id) { %W(#{book2_id}@#{book2_version}) }
  let(:book1) { { book1_id => { "defaultVersion" => book1_version} } }
  let(:book2) { { book2_id => { "defaultVersion" => book2_version} } }
  let(:test_bucket_name) { "acceptance-test-#{SecureRandom.hex(7)}" }
  let(:rex_release_override) { { name: test_bucket_name, region: 'us-east-2' } }
  let(:sqs_override) { {
      todo_jobs_queue_url: sqs_todo_name,
      done_jobs_queue_url: sqs_done_name,
      dead_jobs_queue_url: sqs_dead_name
    } }
  let(:sqs_todo_name) { "acceptance_sqs_todo" }
  let(:sqs_done_name) { "acceptance_sqs_done" }
  let(:sqs_dead_name) { "acceptance_sqs_dead" }
  let(:index_name1) { "#{book1_id}@#{book1_version}"}
  let(:index_name2) { "#{book2_id}@#{book2_version}"}
  let(:search_term1) { 'dramaturgical' }
  let(:search_term2) { 'consequentialism' }

  def init_test(env)
    env.create_dynamodb_table
    env.create_sqs(name: sqs_todo_name)
    env.create_sqs(name: sqs_done_name)
    env.create_sqs(name: sqs_dead_name)
  end

  def make_a_release(book_data, env)
    bucket = env.create_bucket(name: test_bucket_name, region: 'us-east-2')
    bucket.put_object(key: "rex/releases/foobar/rex/release.json", body: book_data)
  end

  def delete_buckets(env)
    env.delete_buckets
  end

  def enqueue_books(env)
    EnqueueIndexJobs.new(todo_url: env.sqs_queue_url(name: sqs_todo_name)).call
  end

  def process_books(env)
    jobs = WorkIndexJobs.new(todo_url: env.sqs_queue_url(name: sqs_todo_name),
                             done_url: env.sqs_queue_url(name: sqs_done_name))
    jobs.call #process book1
    jobs.call #process book2
  end

  def finish_up(env)
    monitor = MonitorIndexJobs.new(todo_url: env.sqs_queue_url(name: sqs_todo_name),
                                   dead_url: env.sqs_queue_url(name: sqs_todo_name),
                                   done_url: env.sqs_queue_url(name: sqs_done_name))
    monitor.call
  end

  def search(books, search_term)
    search_strategy_instance = Books::SearchStrategies::Factory.build(
      book_version_ids: books,
      index_strategy: "I1",
      search_strategy: "S1"
    )

    search_strategy_instance.search(query_string: search_term)
  end

  context "happy path" do
    before do
      allow(Rails.application.secrets).to receive(:rex_release_bucket).and_return(rex_release_override)
      allow(Rails.application.secrets).to receive(:sqs).and_return(sqs_override)
    end

    it "indexes a release & searches" do
      TempAwsEnv.make do |env|
        init_test(env)

        # Step #1 is to create a Rex release with both books
        both_books = { books: book1.merge(book2)}.to_json
        make_a_release(both_books, env)

        # Step #2 is to enqueue the books in the release to SQS.  They go into
        # the todo sqs queue.
        enqueue_books(env)
        expect(BookIndexState.all.count).to eq 2
        expect(TodoJobsQueue.new(url: env.sqs_queue_url(name: sqs_todo_name)).count).to eq 2

        # Step #3 is to index the books.  This reads the todo sqs queue and indexes
        # the book(s) to ElasticSearch
        process_books(env)
        finish_up(env)

        sleep(2) if VCR.current_cassette.try(:recording?)

        # Step #4 is to search the results.  Search each book for a relevant term
        # and verify the hits
        result1 = search(book_1_version_id, search_term1)
        expect(result1["hits"]["hits"].first["highlight"]["visible_content"].first).to include(search_term1)
        result2 = search(book_2_version_id, search_term2)
        expect(result2["hits"]["hits"].first["highlight"]["visible_content"].first).to include(search_term2)

        # Step #5 is to remove the previous release, create a new one, but only with one book
        delete_buckets(env)
        book_subset = { books: book1 }.to_json
        make_a_release(book_subset, env)

        # Step #6 is to enqueue the work into the SQS queues.  There should be only 1 job, the delete job
        enqueue_books(env)
        expect(TodoJobsQueue.new(url: env.sqs_queue_url(name: sqs_todo_name)).count).to eq 1

        # Step #7 is to run the job.
        process_books(env)
        finish_up(env)
        sleep(2) if VCR.current_cassette.try(:recording?)

        # Step #8 is to search the results. Searching second book should result in a
        # missing index exception
        result1 = search(book_1_version_id, search_term1)
        expect(result1["hits"]["hits"].first["highlight"]["visible_content"].first).to include(search_term1)
        expect { search(book_2_version_id, search_term2) }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
      end
    end
  end
end
