require 'aws-sdk-s3'
require_relative '../index_manager'
require_relative '../rex_releases'

desc <<-DESC.strip_heredoc
  Populates Elasticsearch tasks into an SQS queue and triggers launching of
  workers to handle them.
DESC
task :populate_tasks_and_launch_workers, [] do

  current_releases = RexReleases.new
  current_release_ids = current_releases.map(&:id)

  # get from DynamoDB the releases that have been queued or more,
  # find releases that aren't in there, enqueue them

  # get list of active releases

  # find releases that aren't in current releases that are in dynamoDb
  # and enqueue tasks to delete their indexes



  # https://stackoverflow.com/a/8297843 - timeout on process
  # https://stackoverflow.com/a/4327524 - use file lock to ensure only one process running


  # check index ASG # instances, if 1, return
  debugger


  releases = RexReleases.new

  release = releases.first

  t = Time.now; release.books.first.pages; puts "Downloading release took #{Time.now - t} seconds\n"

  debugger

  endpoint = Rails.application.secrets.elasticsearch[:endpoint]
  protocol = endpoint.starts_with?("localhost") ? "http" : "https"

  es_client ||= Elasticsearch::Client.new(
      url: "#{protocol}://#{endpoint}",
      log: true
    )

  index_start_time = Time.now
  release.books.first.pages.each do |page|
    t = Time.now
    es_client.index  index: 'pages', type: 'page', id: page.id, body: page.data
    puts "Page index time: #{Time.now - t}\n"
  end

  puts "Total page index time (#{Time.now - index_start_time})\n"

  # index_manager = IndexManager.new

  # if index_manager.needs_index_update?
  #   # set index ASG desired capacity to 1
  # end

end
