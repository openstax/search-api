require_relative './page'

class Book

  attr_reader :uuid, :version

  def initialize(uuid:, version:)
    @uuid = uuid
    @version = version
  end

  def data
    @data ||= begin
      book_json_url = "https://archive.cnx.org/contents/#{uuid}@#{version}.json"

      uri = URI(book_json_url)
      response = Net::HTTP.get(uri)
      JSON.parse(response)
    end
  end

  def pages
    @pages ||= begin
      page_ids = data['tree']['contents'].flat_map do |chapter|
        (chapter['contents'] || []).map{|page| page['id']}.compact
      end

      page_ids.map do |page_id|
        page_uri = URI("https://archive.cnx.org/contents/#{page_id}.json")
        page_response = Net::HTTP.get(page_uri)

        begin
          Page.new(id: page_id, data: JSON.parse(page_response))
        rescue JSON::ParserError
          # TODO log it
          next
        end
      end.compact
    end
  end

end
