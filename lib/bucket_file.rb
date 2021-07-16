class BucketFile
  def initialize(key:, region:, bucket_name:)
    @key = key
    @region = region
    @bucket_name = bucket_name
  end

  def exists?
    load != :does_not_exist
  end

  def object
    load == :does_not_exist ? nil : load
  end

  def to_hash
    exists? ? JSON.parse(object.body.read) : {}
  end

  protected

  def client
    @client ||= ::Aws::S3::Client.new(region: @region)
  end

  def load
    @object ||= begin
      client.get_object(bucket: @bucket_name, key: @key)
    rescue ::Aws::S3::Errors::NoSuchKey => ee
      :does_not_exist
    end
  end
end
