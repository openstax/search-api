desc <<-DESC.strip_heredoc
  Monitors the done sqs queue.
DESC
task monitor_index_jobs: :environment do
  Rails.logger.info { "Starting monitor_index_jobs..." }

  monitor_index_job = MonitorIndexJobs.new
  stats = monitor_index_job.call

  Rails.logger.info { "Ending monitor_index_jobs w/ stats #{stats.to_s}" }
end
