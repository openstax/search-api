# Load the Rails application.
require_relative 'application'

require 'rescue_from_unless_local'
require 'open_search/elasticsearch_client'

# Initialize the Rails application.
Rails.application.initialize!

