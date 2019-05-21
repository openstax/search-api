desc <<-DESC.strip_heredoc
  Adds indexing jobs (creation and deletion of indexes) into an SQS queue and ensures
  that workers are available to work them.
DESC
task enqueue_index_jobs: :environment do
  Rails.logger.info { "Starting enqueue_index_jobs..." }

  EnqueueIndexJobs.new.call

  # This rake task should implement
  # https://app.zenhub.com/workspaces/openstax-unified-5b71aabe3815ff014b102258/issues/openstax/unified/197

  # Notes:
  #
  # For getting releases we can use
  #
  #   current_releases = RexReleases.new
  #
  # Should we ensure that only one of these jobs is running at one time?  E.g. with
  # https://stackoverflow.com/a/4327524 ?
  #
  # If we don't ensure that only one of these jobs is running at once, we need to make
  # sure it can handle simultaneous runs (which could happen if one run is slow or if
  # a developer runs it manually while cron is still enabled).
  #
end
