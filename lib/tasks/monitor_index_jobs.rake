desc <<-DESC.strip_heredoc
  Monitors the done sqs queue.
DESC
task monitor_index_jobs: :environment do
  Rails.logger.info { "Starting monitor_index_jobs..." }

  monitor_index_job = MonitorIndexJob.new
  monitor_index_job.call
end
