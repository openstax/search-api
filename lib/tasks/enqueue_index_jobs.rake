desc <<-DESC.strip_heredoc
  Adds indexing jobs (creation and deletion of indexes) into an SQS queue and ensures
  that workers are available to work them.
DESC
task enqueue_index_jobs: :environment do
  stats = EnqueueIndexJobs.new.call

  worker_asg = OpenStax::Aws::AutoScalingGroup.new(
    name: Rails.application.secrets.search_worker_asg_name,
    region: ENV.fetch('REGION')
  )

  num_new_jobs = stats[:num_delete_index_jobs] + stats[:num_create_index_jobs]

  if num_new_jobs > 0
    Rails.logger.info("#{EnqueueIndexJobs.log_prefix} increasing worker ASG capacity by up to #{num_new_jobs} nodes")
    worker_asg.increase_desired_capacity(by: num_new_jobs)
  end

  # Should we ensure that only one of these jobs is running at one time?  E.g. with
  # https://stackoverflow.com/a/4327524 ?
  #
  # If we don't ensure that only one of these jobs is running at once, we need to make
  # sure it can handle simultaneous runs (which could happen if one run is slow or if
  # a developer runs it manually while cron is still enabled).
  #
end
