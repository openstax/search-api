require 'aws-sdk-ssm'

desc <<-DESC.strip_heredoc
  Pull the secrets for this environment and application from the AWS Parameter
  Store and use them to write the secrets.yml
DESC
task :install_secrets, [] do
  # Secrets live in the AWS Parameter Store under a /env_name/parameter_namespace/
  # hierarchy.  Several environment variables are set by the AWS cloudformation scripts.
  #
  # This script would take the following Parameter Store values:
  #
  #   /qa/interactions/secret_key = 123456
  #   /qa/interactions/redis/namespace = interactions-dev
  #
  # and (over)write the following to config/secrets.yml:
  #
  #   production:
  #     secret_key: 123456
  #     redis:
  #       namespace: interactions-dev

  region = get_env_var!('REGION')
  env_name = get_env_var!('ENV_NAME')
  namespace = get_env_var!('PARAMETER_NAMESPACE')

  secrets = {}

  client = Aws::SSM::Client.new(region: region)
  client.get_parameters_by_path({path: "/#{env_name}/#{namespace}/",
                                 recursive: true,
                                 with_decryption: true}).each do |response|
    response.parameters.each do |parameter|
      # break out the flattened keys and ignore the env name and namespace
      keys = parameter.name.split('/').reject(&:blank?)[2..-1]
      deep_populate(secrets, keys, parameter.value)
    end
  end

  File.open(File.expand_path("config/secrets.yml"), "w") do |file|
    # write the secrets hash as yaml, getting rid of the "---\n" at the front
    file.write({'production' => secrets}.to_yaml[4..-1])
  end
end

def get_env_var!(name)
  ENV[name].tap do |value|
    raise "Environment variable #{name} isn't set!" if value.nil?
  end
end

def deep_populate(hash, keys, value)
  if keys.length == 1
    hash[keys[0]] = value
  else
    hash[keys[0]] ||= {}
    deep_populate(hash[keys[0]], keys[1..-1], value)
  end
end
