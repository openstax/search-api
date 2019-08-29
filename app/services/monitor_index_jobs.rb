# Monitor the Done jobs from the SQS queue
class MonitorIndexJobs
  prefix_logger "MonitorIndexJobs"

  def initialize(todo_url: Rails.application.secrets.sqs[:todo_jobs_queue_url],
                 dead_url: Rails.application.secrets.sqs[:dead_jobs_queue_url],
                 done_url: Rails.application.secrets.sqs[:done_jobs_queue_url])
    @todo_jobs_queue     = TodoJobsQueue.new(url: todo_url)
    @done_jobs_queue     = DoneJobsQueue.new(url: done_url)
    @dead_queue          = DeadLetterJobsQueue.new(url: dead_url)
    @processed_from_done = 0
    @processed_from_dead = 0
    @desired_capacity_reset_by = 0
    @worker_asg = OpenStax::Aws::AutoScalingGroup.new(
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

      begin
        log_info("Sending job #{dead_job.class.to_s} to dead letter queue")
        Raven.capture_message("Job Found in Dead Letter Queue", :extra => dead_job.inspect)

        dead_job.cleanup_after_call   #delete the message so we dont keep sending to Sentry

        @processed_from_dead += 1
      rescue => ex
        Raven.capture_exception(ex, :extra => dead_job.inspect)
        log_error("dead job error #{ex.message} process #{dead_job.inspect}")
      end
    end
  end

  def reset_desired_capacity_if_needed
    return if Rails.env.development?

    todo_queue_size = @todo_jobs_queue.count

    if todo_queue_size > 0 && @worker_asg&.desired_capacity == 0
      @worker_asg.increase_desired_capacity(by: todo_queue_size)
      log_info("Resetting aws autoscaling desired capacity by #{todo_queue_size}")
      @desired_capacity_reset_by = todo_queue_size
    end
  end

  def stats
    {
      processed_from_done: @processed_from_done,
      processed_from_dead: @processed_from_dead,
      desired_capacity_reset_by: @desired_capacity_reset_by,
    }
  end

  def process_done_jobs
    loop do
      done_job = @done_jobs_queue.read
      break if done_job.nil?

      begin
        log_info("job #{done_job.class.to_s} #{done_job.to_json} started...")

        done_job.call

        @processed_from_done +=1
      rescue => ex
        Raven.capture_exception(ex)
        log_error("done job error #{ex.message} process #{done_job.inspect}")
      end
    end
  end
end
