class DeadLetterJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:todo_jobs_dead_letter_queue_url])
    super(url)
  end
end
