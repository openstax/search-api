desc <<-DESC.strip_heredoc
  Pulls an index job from an SQS queue and works it.
DESC
task work_index_jobs: :environment do
  Rails.logger.info { "Starting work_index_jobs..." }

  instance = OpenStax::Aws::AutoScalingInstance.me
  work_index_job = WorkIndexJobs.new

  while true do
    if instance.terminating_wait?
      instance.continue_to_termination(hook_name: "TerminationHook")
      break
    elsif work_index_job.definitely_out_of_work?
      instance.terminate(should_decrement_capacity: true, continue_hook_name: "TerminationHook")
      break
    else
      stats = work_index_job.call # reads from queue, works the job, writes to done queue
      Rails.logger.info { "work_index_jobs #call w/ stats #{stats.to_s}" }
    end
  end

  Rails.logger.info { "Ending work_index_jobs" }

  # Things to do in this code:
  #
  #   When the work is complete, we want this instance to self-terminate
  #   and simultaneously decrement the desired capacity of the autoscaling
  #   group in which it lives.  (Decrementing the capacity ensures that when
  #   this instance self-terminates, AWS doesn't try to spin up another in its
  #   place.)  This can be done via either of the following tho the first looks
  #   more clear:
  #
  #   - https://docs.aws.amazon.com/sdkforruby/api/Aws/AutoScaling/Instance.html#terminate-instance_method
  #   - https://docs.aws.amazon.com/autoscaling/ec2/userguide/detach-instance-asg.html
  #
  #   It'd also be nice to have a failsafe that terminates this instance no
  #   matter what happens after a defined period (e.g. which could come into play if
  #   this rake task explodes and the "terminate and decrement ASG capacity" code
  #   isn't reached).  We don't want to end up with a pile of workers just burning
  #   money.  A way to do this would be to put a command in the worker's CloudFormation
  #   launch configuration user data like the one in https://askubuntu.com/a/505938 :
  #
  #     sudo shutdown -P +60
  #
  #   If we wanted to be fancy, every iteration of this worker's main loop could cancel
  #   this scheduled shutdown (`sudo shutdown -c`) and reset it for 60 minutes later when
  #   the worker sees more work to do, just in case we have workers that are really
  #   working for that long.

end
