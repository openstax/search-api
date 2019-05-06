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
    new_job = msg_type.build_object(parsed_message)

    #should this be here, or at end of process_index_job#call?
    delete_message(messages.first.receipt_handle)

    new_job
  end

  def delete_message(receipt_handle)
    client.delete_message(queue_url: @url, receipt_handle:receipt_handle)
  end
end
