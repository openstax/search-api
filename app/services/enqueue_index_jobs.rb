# Indexes a book version thru the SQS queuing system
class EnqueueIndexJobs
  prefix_logger "EnqueueIndexJobs"

  def initialize(todo_url: Rails.application.secrets.sqs[:todo_jobs_queue_url])
    @todo_jobs_queue = TodoJobsQueue.new(url: todo_url)
    @new_create_index_jobs = 0
    @new_delete_index_jobs = 0
  end

  def call
    log_info { "Starting..." }

    released_book_ids.each do |book_id|
      ACTIVE_INDEXING_STRATEGY_NAMES.each do |strategy_name|
        existing_book_indexing = find_book_indexing(book_id, strategy_name)

        if existing_book_indexing
          existing_book_indexing.in_demand = true
        else
          enqueue_create_index_job(book_id, strategy_name)
        end
      end
    end

    _, unneeded_book_indexings = index_states.partition(&:in_demand)

    unneeded_book_indexings.each do |unneeded_book_indexing|
      enqueue_delete_index_job(unneeded_book_indexing)
    end

    log_info { "Completed: #{stats}" }

    stats
  end

  private

  def stats
    {
      num_delete_index_jobs: @new_delete_index_jobs,
      num_create_index_jobs: @new_create_index_jobs
    }
  end

  def index_states
    @index_states ||= BookIndexState.live
  end

  def find_book_indexing(book_id, indexing_strategy_name)
    @fast_lookup_hash ||= index_states.each_with_object({}) do |book_indexing, hash|
      hash["#{book_indexing.book_version_id}#{book_indexing.indexing_strategy_name}"] = book_indexing
    end

    @fast_lookup_hash["#{book_id}#{indexing_strategy_name}"]
  end

  def enqueue_create_index_job(book_id, indexing_strategy_name)
    job = CreateIndexJob.new(book_version_id: book_id,
                             indexing_strategy_name: indexing_strategy_name)
    @todo_jobs_queue.write(job)

    BookIndexState.create(book_version_id:  book_id,
                          indexing_strategy_name: indexing_strategy_name)

    @new_create_index_jobs += 1

    log_info { "Enqueued creation for '#{book_id} #{indexing_strategy_name}'" }
  end

  def enqueue_delete_index_job(book_indexing)
    job = DeleteIndexJob.new(book_version_id: book_indexing.book_version_id,
                             indexing_strategy_name: book_indexing.indexing_strategy_name)
    @todo_jobs_queue.write(job)

    book_indexing.mark_queued_for_deletion

    @new_delete_index_jobs += 1

    log_info { "Enqueued deletion for '#{book_indexing.book_version_id} #{book_indexing.indexing_strategy_name}'" }
  end

  def released_book_ids
    @released_book_ids ||= begin
      rex_releases = Rex::Releases.new
      rex_releases.map(&:books).flatten.uniq
    end
  end

  def new_jobs
    @new_delete_index_jobs + @new_create_index_jobs
  end
end
