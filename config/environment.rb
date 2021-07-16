# Load the Rails application.
require_relative 'application'

require 'prefix_logger'
require 'rescue_from_unless_local'
require 'os_elasticsearch_client'
require 'bucket'
require 'bucket_file'
require 'rex/config'
require 'rex/release'
require 'rex/releases'

# Initialize the Rails application.
Rails.application.initialize!
