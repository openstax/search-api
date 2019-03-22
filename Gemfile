source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.2'
# Use sqlite3 as the database for Active Record
gem 'puma', '~> 3.11'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Gives 200 OK from /ping
gem 'openstax_healthcheck'

# For installing secrets on deploy
gem "aws-sdk-ssm"

# For indexing releases
gem "aws-sdk-s3"

# For accessing dynamoDB tables
gem "aws-sdk-dynamodb"

# Versioned API tools
gem "versionist"

gem "elasticsearch", '~> 6.1.0'

gem "whenever"

# Unlike in most of our projects, this is used in production (to set the node type)
gem 'dotenv-rails'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 3.8'

  # Stubs HTTP requests
  gem 'webmock'

  # Records HTTP requests
  gem 'vcr'

  gem 'whenever-test'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
