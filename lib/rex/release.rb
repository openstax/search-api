require 'json'

module Rex
  class Release
    attr_reader :id, :data, :config

    def initialize(id:, data:, config:)
      @id = id
      @data = data.is_a?(String) ? JSON.parse(data) : data
      @config = config.is_a?(String) ? JSON.parse(config) : config
    end

    def books
      @books ||= @data["books"].map do |uuid, info|
        "#{pipeline_version}/#{uuid}@#{info["defaultVersion"]}"
      end
    end

    def pipeline_version
      config['REACT_APP_ARCHIVE_URL']&.match(/\/apps\/archive\/(.*)/).try(:[], 1) || 'legacy'
    end
  end
end
