module Rex
  class Releases
    include Enumerable
    extend Forwardable

    attr_reader :releases

    def_delegators :@releases, :each, :map, :size, :count, :first, :last

    def initialize
      load_releases
    end

    protected

    def load_releases
      @releases = []
      load_release_folder(folder_prefix: 'rex/releases/')
    end

    def load_release_folder(folder_prefix:)
      release_folders =
        s3_client.list_objects(bucket: rex_release_bucket_name,
                               prefix: folder_prefix,
                               delimiter: "/")
          .common_prefixes
          .map(&:prefix)

      return if release_folders.empty?

      release_folders.each do |release_folder|
        begin
          release_json_object = s3_client.get_object(bucket: rex_release_bucket_name,
                                                     key: "#{release_folder}rex/release.json")

          release_id = release_folder.match(/rex\/releases\/(.*)\//)[1]

          @releases.push(Release.new(id: release_id,
                                     data: release_json_object.body.read))
        rescue ::Aws::S3::Errors::NoSuchKey => ee
          load_release_folder(folder_prefix: release_folder)
        end
      end
    end

    def s3_client
      @s3_client ||= ::Aws::S3::Client.new(region: rex_release_bucket_region)
    end

    def rex_release_bucket_name
      Rails.application.secrets.rex_release_bucket[:name]
    end

    def rex_release_bucket_region
      Rails.application.secrets.rex_release_bucket[:region]
    end
  end
end
