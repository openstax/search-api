class AutoScalingGroup
  attr_reader :raw_asg

  delegate_missing_to :@raw_asg

  def initialize(name)
    @name = name

    @raw_asg = Aws::AutoScaling::AutoScalingGroup.new(
      name: name,
      client: autoscaling_client
    )
  end

  def increase_desired_capacity(by:)
    raw_asg.set_desired_capacity(
      {
        desired_capacity: raw_asg.desired_capacity() + by
      })
  end

  def terminate_instance
    return unless Rails.env.production? #what should this be for local?

    instance.detach( { should_decrement_desired_capacity: true })

    Rails.logger.info
      "Instance #{instance.id} being terminated.... " /
      "state: #{instance.lifecycle_state}, " /
      "desired capacity #{raw_asg.desired_capacity}"

    instance.terminate( { should_decrement_desired_capacity: false })
  end

  def autoscaling_client
    @autoscaling_client ||= Aws::AutoScaling::Client.new(region: ENV.fetch('REGION'))
  end

  def instance
    @instance ||= begin
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )

      Aws::AutoScaling::Instance(@name, instance_id)
    end
  end
end
