class TodoJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:todo_jobs_queue_url])
    super(url)
  end

  def write(indexing_job)
    raw_queue.send_message( message_body: indexing_job.to_json )
  end

  def read
    message = raw_queue.receive_messages()
    message.size == 0 ? nil : IndexingJob.new(message)
  end
end
