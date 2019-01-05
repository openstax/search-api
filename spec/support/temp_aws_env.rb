# require_relative '../vcr_helper_methods'

class TempAwsEnv

  include VcrHelperMethods

  def self.make
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


end
