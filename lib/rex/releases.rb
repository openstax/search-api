module Rex
  class Releases
    include Enumerable
    extend Forwardable

    attr_reader :releases, :bucket

    def_delegators :@releases, :each, :map, :size, :count, :first, :last

    def initialize
      @bucket = S3Bucket.new(
        name: Rails.application.secrets.rex_release_bucket[:name],
        region: Rails.application.secrets.rex_release_bucket[:region]
      )
      load_releases
    end

    protected

    def load_releases
      @releases = []
      load_release_folder(folder_prefix: 'rex/releases/')
    end

    def load_release_folder(folder_prefix:)
      release_folders = bucket.folders_under(folder: folder_prefix)
      return if release_folders.empty?

      release_folders.each do |release_folder|
        release_file = bucket.file(key: "#{release_folder}rex/release.json")

        if release_file.exists?
          release_id = release_folder.match(/rex\/releases\/(.*)\//)[1]
          config_file = bucket.file(key: "#{release_folder}rex/config.json")

          @releases.push(Release.new(
            id: release_id,
            data: release_file.to_hash,
            config: config_file.to_hash
          ))
        else
          # This is not the release folder, keep searching deeper
          load_release_folder(folder_prefix: release_folder)
        end
      end
    end

    class S3Bucket
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
        S3File.new(key: key, client: client, bucket: self)
      end

      def client
        @client ||= ::Aws::S3::Client.new(region: @region)
      end
    end

    class S3File
      def initialize(key:, client:, bucket:)
        @key = key
        @client = client
        @bucket = bucket
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

      def load
        @object ||= begin
          @client.get_object(bucket: @bucket.name, key: @key)
        rescue ::Aws::S3::Errors::NoSuchKey => ee
          :does_not_exist
        end
      end
    end
  end
end
