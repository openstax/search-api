# Work the Index jobs SQS queue
#
# There are 2 types of work to do from this queue:
# (1) CreateIndexJob - will (re)build the search index for this book version and indexing version
# (2) DeleteIndexJob - will delete the search indexed for this unneeded book
class WorkIndexJobs
  include Enumerable

  def initialize
    @todo_jobs_queue = TodoJobsQueue.new
    @done_jobs_queue = DoneJobsQueue.new
    @stats = { DeleteIndexJob => 0, CreateIndexJob => 0 }
    @worker_asg_instance = AutoScalingInstance.new
  end

  def each(&block)
    while job = @todo_jobs_queue.read
      @performing = false
      block.call(job)
      break unless @performing
    end
  end

  def perform(job)
    @performing = true

    validate_indexing_version(job)

    starting = Time.now
    es_stats = job.call
    time_took = Time.at(Time.now - starting).utc.strftime("%H:%M:%S")

    Rails.logger.info("OpenSearch: WorkIndexJobs job #{job.class.to_s} took #{time_took} time. json #{job.to_json}")

    enqueue_done_job(job: job,
                     status: DoneIndexJob::Results::STATUS_SUCCESSFUL,
                     es_stats: es_stats,
                     time_took: time_took)

    job.when_completed

    record_job_stat(job)

    job_stats
  rescue InvalidIndexingVersion
    enqueue_done_job(job: job,
                     status: DoneIndexJob::Results::STATUS_INVALID_INDEXING_VERSION)
  rescue => ex   # TODO review error handling with JP
    enqueue_done_job(job: job,
                     status: DoneIndexJob::Results::STATUS_OTHER_ERROR,
                     message: ex.message)
  end

  private

  class InvalidIndexingVersion < StandardError; end

  def validate_indexing_version(job)
    unless ACTIVE_INDEXING_VERSIONS.include?(job.indexing_version)
      raise InvalidIndexingVersion
    end
  end

  def enqueue_done_job(job:, status:, message: nil, time_took: nil, es_stats: nil)
    done_job_results = DoneIndexJob::Results.new(status: status,
                                                message: message,
                                                time_took: time_took,
                                                es_stats: es_stats)

    done_job = DoneIndexJob.new( results: done_job_results,
                            book_version_id: job.book_version_id,
                            indexing_version:job.indexing_version)

    enqueue_to_done(done_job)
  end

  def enqueue_to_done(job)
    @done_jobs_queue.write(job)
  end

  def record_job_stat(job)
    @stats[job.class] += 1
  end

  def job_stats
    {
      num_index_jobs_processed: @stats[CreateIndexJob],
      num_delete_index_jobs_processed: @stats[DeleteIndexJob]
    }
  end

  def worker_asg_name
    Rails.application.secrets.search_worker_asg_name
  end
end
