class DoneJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:done_jobs_queue_url])
    super(url)
  end

  def write(done_job)
    raw_queue.send_message( message_body: done_job.to_json )
  end
end
