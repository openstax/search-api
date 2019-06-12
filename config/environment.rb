# Load the Rails application.
require_relative 'application'

require 'rescue_from_unless_local'
require 'os_elasticsearch_client'

# Initialize the Rails application.
Rails.application.initialize!

