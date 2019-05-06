if Rails.env.test?   #running on travis where no .env would exist
  ENV['REGION'] ||= 'us-east-2'
  ENV['AWS_ACCESS_KEY_ID'] ||= 'xx'
  ENV['AWS_SECRET_ACCESS_KEY'] ||= 'yy'
end

def aws_creds
  if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], ENV['AWS_SESSION_TOKEN'])
  else
    Aws::InstanceProfileCredentials.new.credentials
  end
end

Aws.config.update(
  {
    region: ENV.fetch('REGION'),
    credentials: aws_creds
  })
