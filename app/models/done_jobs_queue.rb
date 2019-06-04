class DoneJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:done_jobs_queue_url])
    super
  end
end
