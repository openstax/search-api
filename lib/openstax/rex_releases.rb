module Openstax
  class RexReleases
    include Enumerable
    extend Forwardable

    attr_reader :releases

    def_delegators :@releases, :each, :size, :count, :first, :last

    def initialize
      load_releases
    end

    protected

    def load_releases
      release_folders =
        s3_client.list_objects(bucket: rex_release_bucket_name,
                               prefix: "rex/releases/",
                               delimiter: "/")
          .common_prefixes
          .map(&:prefix)

      @releases = []

      release_folders.each do |release_folder|
        begin
          release_json_object = s3_client.get_object(bucket: rex_release_bucket_name,
                                                     key: "#{release_folder}rex/release.json")

          release_id = release_folder.match(/rex\/releases\/(.*)\//)[1]

          @releases.push(RexRelease.new(id: release_id,
                                        data: release_json_object.body.read))
        rescue Aws::S3::Errors::NoSuchKey => ee
          next
        end
      end
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: rex_release_bucket_region)
    end

    def rex_release_bucket_name
      Rails.application.secrets.rex_release_bucket[:name]
    end

    def rex_release_bucket_region
      Rails.application.secrets.rex_release_bucket[:region]
    end

  end
end
