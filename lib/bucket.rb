class Bucket
  attr_reader :name

  def initialize(name:, region:)
    @name = name
    @region = region
  end

  def folders_under(folder:)
    client.list_objects(bucket: @name, prefix: folder, delimiter: "/")
          .common_prefixes
          .map(&:prefix)
  end

  def file(key:)
    BucketFile.new(key: key, region: @region, bucket_name: name)
  end

  def client
    @client ||= ::Aws::S3::Client.new(region: @region)
  end
end
