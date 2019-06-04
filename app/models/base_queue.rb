class BaseQueue
  def initialize(url:)
    @raw_queue = Aws::SQS::Queue.new(url, client)
  end

  def read
    messages = raw_queue.receive_messages()
    return nil if messages.size == 0

    parsed_message = JSON.parse(messages.first.body).with_indifferent_access
    msg_type = parsed_message[:type].constantize

    receipt_handle = messages.first.receipt_handle
    cleanup_after_call_proc = -> {
      # not sure what this id is used for, but it doesnt seem to affect
      # deleting the message received.  So, using a random uuid.
      raw_queue.delete_messages({entries: [{id: SecureRandom.uuid,
                                            receipt_handle: receipt_handle}]})
    }
    msg_type.build_object(params: parsed_message,
                          cleanup_after_call: cleanup_after_call_proc)
  end

  def write(job)
    raw_queue.send_message( message_body: job.to_json )
  end

  def count
    raw_queue.attributes['ApproximateNumberOfMessages'].to_i
  end

  protected

  attr_reader :raw_queue

  def client
    Aws::SQS::Client.new(region: ENV.fetch('REGION'))
  end
end
