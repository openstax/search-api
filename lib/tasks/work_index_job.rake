desc <<-DESC.strip_heredoc
  Pulls an index job from an SQS queue and works it.
DESC
task work_index_job: :environment do

  Rails.logger.info { "Ran placeholder work_index_job task!" }

end
