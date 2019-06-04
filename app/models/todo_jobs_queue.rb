class TodoJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:todo_jobs_queue_url])
    super
  end
end
