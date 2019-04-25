class AutoScalingGroup
  delegate_missing_to :@raw_asg

  def initialize(name)
    @raw_asg = Aws::AutoScaling::AutoScalingGroup.new(
      name: name,
      client: Aws::AutoScaling::Client.new(region: ENV.fetch('REGION'))
    )
  end

  def increase_desired_capacity(by:)
    raw_asg.set_desired_capacity(raw_asg.get_desired_capacity() + by)
  end

  protected

  attr :raw_asg
end
