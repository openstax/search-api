require 'aws-sdk-s3'
require_relative '../index_manager'
require_relative '../rex_releases'

desc <<-DESC.strip_heredoc
  Checks if there are new releases to be indexed and if so, launches instance
  to index them.
DESC
task :launch_index_update_if_needed, [] do

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
