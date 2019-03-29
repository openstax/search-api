# require_relative '../vcr_helper_methods'

class TempAwsEnv

  include VcrHelperMethods

  @@have_switched_to_temporary_credentials = false

  def self.make
    switch_to_temporary_credentials

    begin
      env = new()
      yield(env)
    ensure
      env.cleanup!
    end
  end

  def initialize(region: "us-east-1")
    @region = region
    @buckets = []
    @es_domain_names_to_regions = {}
    @random_string_count = 0
  end

  def create_bucket(name:, region: @region, filter_name: true)
    filter_value(value: name, with: "some_bucket_name") if filter_name
    Aws::S3::Bucket.new(name, client: Aws::S3::Client.new(region: region)).tap do |bucket|
      bucket.create
      @buckets.push(bucket)
    end
  end

  def create_elasticsearch_domain(name:, region: @region, restrict_access_to_me: true, filter: true)
    filter_value(value: name, with: "some_esdomain_name") if filter

    resp = aws_es_client(region).create_elasticsearch_domain({
      domain_name: name,
      elasticsearch_version: "6.4",
      elasticsearch_cluster_config: {
        instance_type: "m4.xlarge.elasticsearch",
        instance_count: 1,
      },
      ebs_options: {
        ebs_enabled: true,
        volume_type: "gp2",
        volume_size: 10,
      },
      access_policies: {
        "Version" => "2012-10-17",
        "Statement" => [
          {
            "Effect" => "Allow",
            "Action" => %w(es:ESHttpDelete es:ESHttpGet es:ESHttpHead es:ESHttpPost es:ESHttpPut),
            "Principal" => { "AWS" => (restrict_access_to_me ? ENV['AWS_MY_ARN'] : "*") },
            "Resource" => "arn:aws:es:#{region}:#{ENV['AWS_ACCOUNT_ID']}:domain/#{name}/*"
          }
        ]
      }.to_json
    })

    @es_domain_names_to_regions[name] = region

    do_not_record_or_playback do
      until es_domain_created?(region: region, name: name) do
        sleep(30)
        Rails.logger.debug("Waiting for #{name} ES domain to create")
      end
    end

    es_domain_status(region: region, name: name).tap do |domain_status|
      random_part_of_endpoint = domain_status.endpoint.match(/([a-z0-9]*).us-east-1.es.amazonaws.com/)[1]
      filter_value(value: random_part_of_endpoint, with: "randompartofendpoint") if filter
    end
  end

  def cleanup!
    @buckets.each{|bucket| bucket.delete!}
    @es_domain_names_to_regions.each do |domain_name, region|
      aws_es_client(region).delete_elasticsearch_domain(domain_name: domain_name)
    end
  end

  protected

  def self.switch_to_temporary_credentials
    # In the VCR configs, we have calls that mask AWS credentials in recorded AWS HTTP
    # interactions.  Just in case that ever doesn't work, this function changes the
    # credentials that are used over to temporary credentials (via an AWS STS call).
    # The temporary credentials expire after 15 minutes.

    # We only need to switch to temporary credentials if we're recording a cassette; if we
    # aren't, the non-temporary credentials aren't going to be written to a cassette.  Also,
    # we don't want to run these HTTP requests if we are just doing playback because below we
    # exempt them from being recorded at all (for security); if we make requests that aren't
    # present in the cassette during playback, VCR chokes.

    return if !VCR.current_cassette.try(:recording?)

    # We only need to switch once; after we switch the env vars are set

    return if @@have_switched_to_temporary_credentials

    begin
      # Disable VCR while we get the new credentials, because if we wrote the non-temp
      # credentials to a cassette, that'd kind of defeat the purpose of getting temp
      # ones

      ENV['VCR_IGNORE_REQUESTS_TEMPORARILY'] = 'true'

      ENV['AWS_MY_ARN'] = Aws::IAM::CurrentUser.new(region: "us-east-1").arn
      filter_env_var('AWS_MY_ARN')

      sts_client = Aws::STS::Client.new(region: "us-east-1")
      resp = sts_client.get_session_token({duration_seconds: 3600})
      @@temporary_credentials = resp.credentials

      ENV['AWS_ACCESS_KEY_ID'] = resp.credentials.access_key_id
      ENV['AWS_SECRET_ACCESS_KEY'] = resp.credentials.secret_access_key
      ENV['AWS_SESSION_TOKEN'] = resp.credentials.session_token
      filter_env_var('AWS_ACCESS_KEY_ID')
      filter_env_var('AWS_SECRET_ACCESS_KEY')
      filter_env_var('AWS_SESSION_TOKEN')

      ENV['AWS_ACCOUNT_ID'] = sts_client.get_caller_identity({})[:account]
      filter_env_var('AWS_ACCOUNT_ID')

      @@have_switched_to_temporary_credentials = true
    ensure
      ENV.delete('VCR_IGNORE_REQUESTS_TEMPORARILY')
    end
  end

  def aws_es_client(region)
    Aws::ElasticsearchService::Client.new(region: region)
  end

  def es_domain_created?(region:, name:)
    domain_status = es_domain_status(region: region, name: name)
    domain_status.created == true && domain_status.processing == false && domain_status.endpoint.present?
  end

  def es_domain_status(region:, name:)
    aws_es_client(region).describe_elasticsearch_domain(domain_name: name).domain_status
  end

end
