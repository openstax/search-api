desc <<-DESC.strip_heredoc
  Adds indexing jobs (creation and deletion of indexes) into an SQS queue and ensures
  that workers are available to work them.
DESC
task enqueue_index_jobs: :environment do

  Rails.logger.info { "Ran placeholder enqueue_index_jobs task!" }

end
