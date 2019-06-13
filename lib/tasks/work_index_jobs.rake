desc <<-DESC.strip_heredoc
  Pulls an index job from an SQS queue and works it.
DESC
task work_index_jobs: :environment do
  Rails.logger.info { "work_index_jobs: Started" }

  instance = OpenStax::Aws::AutoScalingInstance.me
  work_index_job = WorkIndexJobs.new

  # If exceptions happen in the loop below, we need to rescue them and keep looping,
  # because if we don't, our instance will never be able to get out of an eventual
  # Terminating:Wait state.

  while true do
    begin
      if instance.terminating_wait?
        Rails.logger.info { "work_index_jobs: in Terminating:Wait, continuing to Termination"}
        instance.continue_to_termination(hook_name: "TerminationHook")
        break
      elsif work_index_job.definitely_out_of_work?
        Rails.logger.info { "work_index_jobs: out of work, terminating"}
        instance.terminate(should_decrement_desired_capacity: true, continue_hook_name: "TerminationHook")
        break
      else
        Rails.logger.info { "work_index_jobs: starting #call"}
        stats = work_index_job.call # reads from queue, works the job, writes to done queue
        Rails.logger.info { "work_index_jobs: #call finished #{stats.to_s}" }
      end
    rescue Aws::AutoScaling::Errors::ScalingActivityInProgress => ee
      Rails.logger.info { "work_index_jobs: Termination interrupted because scaling activity in progress.  Will retry in 30 seconds."}
      sleep(30)
    rescue => ee
      Raven.capture_exception(ee)
      Rails.logger.info { "work_index_jobs: A #{ee.class.name} exception occurred.  Will continue working in 60 seconds."}
      sleep(60)
    end
  end

  Rails.logger.info { "work_index_jobs: Ended" }
end
