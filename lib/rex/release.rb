require 'json'

module Rex
  class Release
    attr_reader :id, :data, :config

    def initialize(id:, data:, config:)
      @id = id
      @data = data.is_a?(String) ? JSON.parse(data) : data
      @config = config
    end

    def books
      @books ||= @data["books"].map do |uuid, info|
        "#{config.pipeline_version || 'legacy'}/#{uuid}@#{info["defaultVersion"]}"
      end
    end
  end
end
