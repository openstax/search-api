# Work Index jobs from the SQS queue
#
# There are 2 types of work to do from this queue:
# (1) CreateIndexJob - will (re)build the search index for this book version and indexing version
# (2) DeleteIndexJob - will delete the search indexed for this unneeded book
class WorkIndexJobs
  def initialize
    @todo_jobs_queue        = TodoJobsQueue.new
    @done_jobs_queue        = DoneJobsQueue.new
    @stats                  = { DeleteIndexJob => 0, CreateIndexJob => 0 }
    @definitely_out_of_work = false
  end

  def definitely_out_of_work?
    @definitely_out_of_work
  end

  def call
    job = @todo_jobs_queue.read

    if job.nil?
      @definitely_out_of_work = true
      return job_stats
    else
      @definitely_out_of_work = false
    end

    begin
      validate_indexing_strategy_name(job)
      Rails.logger.info("WorkIndexJobs: job #{job.class.to_s} #{job.to_json} started...")

      starting = Time.now
      es_stats = job.call
      time_took = Time.at(Time.now - starting).utc.strftime("%H:%M:%S")

      Rails.logger.info("WorkIndexJobs: job #{job.class.to_s} #{job.to_json} took #{time_took} time.")

      enqueue_done_job(job: job,
                       status: DoneIndexJob::STATUS_SUCCESSFUL,
                       es_stats: es_stats,
                       time_took: time_took)
    rescue InvalidIndexingStrategy => ex
      Raven.capture_exception(ex)
      Rails.logger.error("Invalid indexing strategy for #{job.to_json}. #{ex.message}")
      enqueue_done_job(job: job,
                       status: DoneIndexJob::STATUS_INVALID_INDEXING_STRATEGY)
    rescue OpenStax::HTTPError => ex
      Raven.capture_exception(ex)
      Rails.logger.error("OpenStax HTTP error #{job.to_json}. #{ex.message}")
      enqueue_done_job(job: job,
                       status: DoneIndexJob::STATUS_HTTP_ERROR)
    rescue => ex
      Raven.capture_exception(ex)
      Rails.logger.error("Exception occurred on #{job.to_json}. #{ex.message}")
      enqueue_done_job(job: job,
                       status: DoneIndexJob::STATUS_OTHER_ERROR,
                       message: ex.message)
    end

    job_stats
  end

  private

  class InvalidIndexingStrategy < StandardError; end

  def validate_indexing_strategy_name(job)
    unless ACTIVE_INDEXING_STRATEGY_NAMES.include?(job.indexing_strategy_name)
      raise InvalidIndexingStrategy
    end
  end

  def enqueue_done_job(job:, status:, message: nil, time_took: nil, es_stats: nil)
    done_job = DoneIndexJob.new(status: status,
                                message: message,
                                ran_job: job,
                                time_took: time_took,
                                es_stats: es_stats)
    enqueue_to_done(done_job)

    record_job_stat(job)
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
end
