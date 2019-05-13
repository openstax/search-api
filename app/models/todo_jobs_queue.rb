class TodoJobsQueue < BaseQueue
  def initialize(url: Rails.application.secrets.sqs[:todo_jobs_queue_url])
    super(url)
  end

  def write(index_job)
    raw_queue.send_message( message_body: index_job.to_json )
  end

  def read
    messages = raw_queue.receive_messages()
    return nil if messages.size == 0

    parsed_message = JSON.parse(messages.first.body).with_indifferent_access
    msg_type = parsed_message[:type].constantize

    receipt_handle = messages.first.receipt_handle
    when_completed_proc = -> {
      raw_queue.delete_messages({entries: [{id: SecureRandom.uuid,
                                            receipt_handle: receipt_handle}]})
    }
    new_job = msg_type.build_object(body: parsed_message,
                                    when_completed_proc: when_completed_proc)

    new_job
  end
end
