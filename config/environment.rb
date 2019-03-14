# Load the Rails application.
require_relative 'application'

Dir[Rails.root.join("lib/openstax/cnx/cnx.rb")].each { |f| require f }

# Initialize the Rails application.
Rails.application.initialize!

