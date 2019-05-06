# Process the Index jobs SQS queue
#
# There are 2 types of work to do from this queue:
# (1) CreateIndexJob - will (re)build the search index for this book version and indexing version
# (2) DeleteIndexJob - will delete the search indexed for this unneeded book
class ProcessIndexJobs
  def initialize
    @todo_jobs_queue = TodoJobsQueue.new
    @done_jobs_queue = DoneJobsQueue.new
    @stats = { DeleteIndexJob => 0, CreateIndexJob => 0 }
    @worker_asg_instance = AutoScalingInstance.new
  end

  def call
    loop do
      job = @todo_jobs_queue.read
      break if job.nil?

      begin
        starting = Time.now
        es_stats = job.call
        time_took = Time.at(Time.now - starting).utc.strftime("%H:%M:%S")

        Rails.logger.info("OpenSearch: ProcessIndexJobs job #{job.class.to_s} took #{time_took} time. json #{job.to_json}")

        enqueue_done_job(job: job,
                         status: DoneIndexJob::Status::STATUS_SUCCESSFUL,
                         es_stats: es_stats,
                         time_took: time_took)
      rescue BaseIndexJob::InvalidIndexingVersion
        enqueue_done_job(job: job,
                         status: DoneIndexJob::Status::STATUS_INVALID_INDEXING_VERSION)
      rescue => ex   # TODO review error handling with JP
        enqueue_done_job(job: job,
                         status: DoneIndexJob::Status::STATUS_OTHER_ERROR,
                         message: ex.message)
      end

      record_job_stat(job)
    end

    @worker_asg_instance.terminate_instance

    job_stats
  end

  private

  def enqueue_done_job(job:, status:, message: nil, time_took: nil, es_stats: nil)
    done_job_status = DoneIndexJob::Status.new(status: status,
                                          message: message,
                                          time_took: time_took,
                                          es_stats: es_stats)

    done_job = DoneIndexJob.new( status: done_job_status,
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
