class BaseQueue
  def initialize(url)
    @raw_queue = Aws::SQS::Queue.new(url, client)
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
