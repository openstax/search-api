class AutoScalingInstance
  def initialize(autoscaling_group_name: Rails.application.secrets.search_worker_asg_name)
    @autoscaling_group_name = autoscaling_group_name
  end

  def terminate_instance
    return unless Rails.env.production?

    Rails.logger.info
    "Instance #{instance.id} being terminated.... " /
      "state: #{instance.lifecycle_state}, " /
      "desired capacity #{raw_asg.desired_capacity}"

    instance.terminate( { should_decrement_desired_capacity: false })
  end

  def instance
    @instance ||= begin
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )

      Aws::AutoScaling::Instance(@autoscaling_group_name, instance_id)
    end
  end
end
