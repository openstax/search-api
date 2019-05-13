# Indexes a book version thru the SQS queuing system
class EnqueueIndexJobs
  def initialize
    @todo_jobs_queue = TodoJobsQueue.new
    @new_create_index_jobs = 0
    @new_delete_index_jobs = 0
    @worker_asg = AutoScalingGroup.new(worker_asg_name)
  end

  def call
    released_book_ids.each do |book_id|
      ACTIVE_INDEXING_VERSIONS.each do |indexing_version|
        existing_book_indexing = find_book_indexing(book_id, indexing_version)

        if existing_book_indexing
          existing_book_indexing.in_demand = true
        else
          enqueue_create_index_job(book_id, indexing_version)
        end
      end
    end

    _, unneeded_book_indexings = index_states.partition(&:in_demand)

    unneeded_book_indexings.each do |unneeded_book_indexing|
      enqueue_delete_index_job(unneeded_book_indexing)
    end

    # TODO will redo to work with JP's aws instance layer above
    # @worker_asg.increase_desired_capacity(by: new_jobs)

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

  def find_book_indexing(book_id, indexing_version)
    @fast_lookup_hash ||= index_states.each_with_object({}) do |book_indexing, hash|
      hash["#{book_indexing.book_version_id}#{book_indexing.indexing_version}"] = book_indexing
    end

    @fast_lookup_hash["#{book_id}#{indexing_version}"]
  end

  def worker_asg_name
    Rails.application.secrets.search_worker_asg_name
  end

  def enqueue_create_index_job(book_id, indexing_version)
    job = CreateIndexJob.new(book_version_id: book_id,
                             indexing_version: indexing_version)
    @todo_jobs_queue.write(job)

    BookIndexState.create(book_version_id:  book_id,
                          indexing_version: indexing_version)

    @new_create_index_jobs += 1

    Rails.logger.info "OpenSearch: Book version '#{book_id} #{indexing_version}' enqueued for indexing"
  end

  def enqueue_delete_index_job(book_indexing)
    job = DeleteIndexJob.new(book_version_id: book_indexing.book_version_id,
                             indexing_version: book_indexing.indexing_version)
    @todo_jobs_queue.write(job)

    book_indexing.mark_queued_for_deletion

    @new_delete_index_jobs += 1

    Rails.logger.info "OpenSearch: Book version '#{book_indexing.book_version_id} #{book_indexing.indexing_version}' enqueued for deleting"
  end

  def released_book_ids
    @released_book_ids ||= begin
      rex_releases = OpenStax::RexReleases.new
      rex_releases.map(&:books).flatten.uniq
    end
  end

  def new_jobs
    @new_delete_index_jobs + @new_create_index_jobs
  end
end
