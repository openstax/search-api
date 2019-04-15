class AutoScaling
  def self.set_desired_capacity(group_name:, desired_capacity:)
    Rails.logger.info "AutoScaling#set_worker_capacity for "\
                      "#{group_name} from #{group(group_name).desired_capacity} "\
                      "to #{desired_capacity}"

    group(group_name).set_desired_capacity(
      {
        desired_capacity: desired_capacity
      }
    )
  end

  private

  def self.group(group_name)
    Aws::AutoScaling::AutoScalingGroup.new(name: group_name, client: client)
  end

  def self.client
    Aws::AutoScaling::Client.new(region: ENV.fetch('REGION'))
  end
end
