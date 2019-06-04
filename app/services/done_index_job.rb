class DoneIndexJob < BaseIndexJob
  attr_reader :status,
              :ran_job,
              :es_stats,
              :time_took,
              :message,
              :book_version_id,
              :indexing_strategy_name

  STATUS = [
    STATUS_SUCCESSFUL                = "successful",
    STATUS_INVALID_INDEXING_STRATEGY = "invalid indexing strategy",
    STATUS_OTHER_ERROR               = "other error"
  ]

  def self.build_object(params:, cleanup_after_call:)
    ran_job_params = params[:ran_job]
    ran_job_type = ran_job_params[:type].constantize
    ran_job = ran_job_type.build_object(params: ran_job_params)

    new(status: params[:status],
        es_stats: params[:es_stats],
        time_took: params[:time_took],
        message: params[:message],
        cleanup_after_call: cleanup_after_call,
        ran_job: ran_job)
  end

  def initialize(status: STATUS_SUCCESSFUL,
                 es_stats: nil,
                 time_took: nil,
                 ran_job: nil,
                 message: nil,
                 cleanup_after_call: nil)
    super(cleanup_after_call: cleanup_after_call)
    @status = status
    @es_stats = es_stats
    @time_took = time_took
    @message = message
    @ran_job = ran_job
    @book_version_id = ran_job.book_version_id
    @indexing_strategy_name = ran_job.indexing_strategy_name
  end

  def successful?
    status == STATUS_SUCCESSFUL
  end

  def as_json(*)
    {
      type: type,
      status: status,
      es_stats: es_stats,
      time_took: time_took,
      ran_job: ran_job,
      message: message
    }
  end

  private

  def _call
    if successful?
      ran_job.cleanup_when_done
    else
      Raven.capture_message("Job in Error Found in Done Queue", :extra => inspect)
      ran_job.remove_associated_book_index_state
    end
  end
end
