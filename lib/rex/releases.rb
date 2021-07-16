module Rex
  class Releases
    include Enumerable
    extend Forwardable

    attr_reader :releases, :bucket

    def_delegators :@releases, :each, :map, :size, :count, :first, :last

    def initialize
      @bucket = Bucket.new(
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
            config: Config.new(data: config_file.to_hash)
          ))
        else
          # This is not the release folder, keep searching deeper
          load_release_folder(folder_prefix: release_folder)
        end
      end
    end
  end
end
