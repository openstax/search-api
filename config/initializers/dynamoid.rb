require 'dynamoid'

# DynamoDB
# (1) (dev only) run `rake dynamoid:create_tables` to create the tables
# (2) aws creds set in aws.rb
Dynamoid.configure do |config|
  config.namespace = ""   # no prefix; full table name set in secrets.yml
  config.timestamps = true
  config.logger.level = :error
end
