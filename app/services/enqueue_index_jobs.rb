# Indexes a book version thru the SQS queuing system
#
# @params indexing_version e.g., Search::BookVersions::I1::IndexingStrategy::VERSION
class EnqueueIndexJobs
  def initialize
    @todo_jobs_queue = TodoJobsQueue.new
  end

  def process_rex_releases
    rex_releases = OpenStax::RexReleases.new
    books_ids = rex_releases.map{ |release| release.books }.flatten

    books_ids.each do |book_id|
      ACTIVE_INDEXING_STRATEGIES.each do |indexing_strategy|
        process_book(book_id, indexing_strategy.new.version)
      end
    end

    check_for_books_to_delete

    AutoScaling.set_desired_capacity(group_name: asg_name, desired_capacity: @todo_jobs_queue.count)
  end

  private

  def book_indexings
    @book_indexings ||= BookIndexing.valid_book_indexings
  end

  def asg_name
    Rails.application.secrets.search_worker_asg_name
  end

  def process_book(book_id, indexing_version)
    book_found_in_indexing = find_book_in_indexing(book_id, indexing_version)

    book_found_in_indexing.in_demand = true    # this book is still needed in elastic search

    unless book_found_in_indexing
      job = IndexingJob.new(book_version_id: book_id, indexing_version: indexing_version)
      enqueue_book(job, BookIndexing::PENDING)
    end
  end

  def check_for_books_to_delete
    books_to_be_deleted = book_indexings.select do |book_indexing|
      book_indexing.in_demand == false
    end

    books_to_be_deleted.each do ||
      job = DeletingJob.new(book_version_id: book_id, indexing_version: indexing_version)
      enqueue_book(job, BookIndexing::DELETE_PENDING)
    end
  end

  def find_book_in_indexing(book_id, indexing_version)
    book_indexings.detect do |book_indexing|
      book_indexing.book_version_id == book_id &&
         book_indexing.indexing_version == indexing_version
    end
  end

  def enqueue_book(job, state)
    @todo_jobs_queue.write(job)

    BookIndexing.create(book_version_id: book_id, indexing_version: indexing_version, state: state)

    Rails.logger.info "Open-Search: Book version #{book_id} #{indexing_version} loaded into todo_job_queue"
  end
end
