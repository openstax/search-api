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
  end

  def create_bucket(name:, region: @region, filter_name: true)
    filter_value(value: name, with: "some_bucket_name") if filter_name
    Aws::S3::Bucket.new(name, client: Aws::S3::Client.new(region: region)).tap do |bucket|
      bucket.create
      @buckets.push(bucket)
    end
  end

  def cleanup!
    @buckets.each{|bucket| bucket.delete!}
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

      sts_client = Aws::STS::Client.new(region: "us-east-1")
      resp = sts_client.get_session_token({duration_seconds:900})
      @@temporary_credentials = resp.credentials

      ENV['AWS_ACCESS_KEY_ID'] = resp.credentials.access_key_id
      ENV['AWS_SECRET_ACCESS_KEY'] = resp.credentials.secret_access_key
      ENV['AWS_SESSION_TOKEN'] = resp.credentials.session_token

      filter_env_var('AWS_ACCESS_KEY_ID')
      filter_env_var('AWS_SECRET_ACCESS_KEY')
      filter_env_var('AWS_SESSION_TOKEN')

      @@have_switched_to_temporary_credentials = true
    ensure
      ENV.delete('VCR_IGNORE_REQUESTS_TEMPORARILY')
    end
  end

end
