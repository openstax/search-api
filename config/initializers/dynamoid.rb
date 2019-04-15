require 'dynamoid'

Dynamoid.configure do |config|
  config.access_key = ENV.fetch('AWS_ACCESS_KEY_ID')
  config.secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY')
  config.region = ENV.fetch('REGION')
  config.namespace = 'open_search'
  config.timestamps = false
end
