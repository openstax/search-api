# Indexes a book version thru the SQS queuing system
#
# @params indexing_version e.g., Search::BookVersions::I1::IndexingStrategy::VERSION
class EnqueueIndexJobs
  def initialize
    @todo_jobs_queue = TodoJobsQueue.new
    @new_create_index_jobs = 0
    @new_delete_index_jobs = 0
    @worker_asg = AutoScalingGroup.new(worker_asg_name)
  end

  def execute
    released_books_ids.each do |book_id|
      ACTIVE_INDEXING_STRATEGIES.each do |indexing_strategy|
        existing_book_indexing = find_book_indexing(book_id, indexing_strategy)

        if existing_book_indexing
          # this book is still needed in elastic search
          existing_book_indexing.in_demand = true
        else
          # Isn't indexed so let's get that process started!
          enqueue_create_index_job(book_id, indexing_strategy)
        end
      end
    end

    # Find the indexes that are no longer needed, and enqueue work to delete them

    in_demand_book_indexings, unneeded_book_indexings = book_indexings.partition(&:in_demand)

    unneeded_book_indexings.each do |unneeded_book_indexing|
      enqueue_delete_index_job(unneeded_book_indexing)
    end

    @worker_asg.increase_desired_capacity(by: new_jobs)
  end

  private

  def book_indexings
    @book_indexings ||= BookIndexing.active_book_indexings
  end

  def find_book_indexing(book_id, indexing_strategy)
    @fast_lookup_hash ||= book_indexings.each_with_object({}) do |book_indexing, hash|
      hash["#{book_indexing.book_id}#{book_indexing.indexing_strategy}"] = book_indexing
    end

    @fast_lookup_hash["#{book_id}#{indexing_strategy}"]
  end

  def worker_asg_name
    Rails.application.secrets.search_worker_asg_name
  end

  def enqueue_create_index_job(book_id, indexing_version)
    job = IndexingJob.new(book_version_id: book_id, indexing_version: indexing_version)
    @todo_jobs_queue.write(job)

    BookIndexing.create(book_version_id: book_id, indexing_version: indexing_version)

    @new_create_index_jobs += 1

    Rails.logger.info "Open-Search: Book version #{book_id} #{indexing_version} loaded into todo_job_queue"
  end

  def enqueue_delete_index_job(book_indexing)
    # write DeleteIndexJob to todo queue
    # mark book_indexing as pending delete
    @new_delete_index_jobs += 1
  end

  def released_book_ids
    @released_book_ids ||= begin
      rex_releases = OpenStax::RexReleases.new
      rex_releases.map{ |release| release.books }.flatten
    end
  end

  def new_jobs
    @new_delete_index_jobs + @new_create_index_jobs
  end
end
