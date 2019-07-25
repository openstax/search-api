if Rails.env.test?   #running on travis where no .env would exist
  ENV['REGION'] ||= 'us-east-2'
  ENV['AWS_ACCESS_KEY_ID'] ||= 'xx'
  ENV['AWS_SECRET_ACCESS_KEY'] ||= 'yy'
end

def aws_creds
  if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], ENV['AWS_SESSION_TOKEN'])
  else
    Aws::InstanceProfileCredentials.new
  end
end

def use_aws?
  !Rails.env.development? ||
  ENV['USE_AWS'] ||
  (ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'])
end

# Don't force AWS usage in development unless some env vars are set.  Configuring AWS
# in development when these vars are not set causes a long delay when loading the rails
# environment, because the code tries to load the instance profile credentials and that
# has to timeout before failing.

if use_aws?
  Aws.config.update({
    region: ENV.fetch('REGION'),
    credentials: aws_creds
  })
end
