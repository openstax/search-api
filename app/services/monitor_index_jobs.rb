# Monitor the Done jobs from the SQS queue
class MonitorIndexJobs
  def initialize
    @todo_jobs_queue     = TodoJobsQueue.new
    @done_jobs_queue     = DoneJobsQueue.new
    @dead_queue          = DeadLetterJobsQueue.new
    @processed_from_done = 0
    @desired_capacity_reset_by = 0
    @worker_asg          = OpenStax::Aws::AutoScalingGroup.new(
      name: Rails.application.secrets[:search_worker_asg_name],
      region: ENV.fetch('REGION') )
  end

  def call
    process_done_jobs
    notify_sentry_for_dead_letter_queue
    reset_desired_capacity_if_needed

    stats
  end

  private

  def notify_sentry_for_dead_letter_queue
    loop do
      dead_job = @dead_queue.read
      break if dead_job.nil?

      Raven.capture_message("Job Found in Dead Letter Queue", :extra => dead_job.inspect)

      dead_job.cleanup_after_call   #delete the message so we dont keep sending to Sentry
    end
  end

  def reset_desired_capacity_if_needed
    todo_queue_size = @todo_jobs_queue.count

    if todo_queue_size > 0 && @worker_asg.desired_capacity == 0
      @worker_asg.increase_desired_capacity(by: todo_queue_size)
      Rails.logger.info("MonitorIndexJobs: Resetting aws autoscaling desired capacity by #{todo_queue_size}")
      @desired_capacity_reset_by = todo_queue_size
    end
  end

  def stats
    {
      processed_from_done: @processed_from_done,
      desired_capacity_reset_by: @desired_capacity_reset_by,
    }
  end

  private
  def process_done_jobs
    loop do
      done_job = @done_jobs_queue.read
      break if done_job.nil?

      Rails.logger.info("MonitorIndexJobs: job #{done_job.class.to_s} #{done_job.to_json} started...")

      done_job.call

      @processed_from_done +=1
    end
  end
end
