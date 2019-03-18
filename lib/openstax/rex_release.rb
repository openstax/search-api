require 'json'

module Openstax
  class RexRelease

    attr_reader :id, :data

    def initialize(id:, data:)
      @id = id
      @data = data

      if @data.is_a?(String)
        @data = JSON.parse(@data)
      end
    end

    def books
      @books ||= @data["books"].map do |uuid, info|
        Book.new(uuid: uuid, version: info["defaultVersion"])
      end
    end

  end
end
