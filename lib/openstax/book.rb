require_relative './page'

module Openstax
  # A Openstax::Book is the object that "represents" the book to the search
  # world.  A book is composed of pages, and pages are composed of elements.
  #
  # Selected elements can be parsed out of the pages.
  class Book
    CNX_URL_PREFIX = 'https://archive.cnx.org/contents'

    attr_reader :uuid, :version

    def initialize(uuid:, version:)
      @uuid = uuid
      @version = version
    end

    # ******************************************************************************************
    #
    # Let's consider using the existing book parsing logic in tutor-server with the tutor-
    # specific code removed.  It has a lot of implementation already done for us, and in an
    # approach where none of the indexing knowledge lives here, we won't need the index-specific
    # bits currently in the code below.
    #
    # In that implementation, a Book structure looks like this:
    #
    #   * A Book is at the top-level
    #   * Pages are at the bottom-level
    #   * In between the top and bottom levels are "parts", which can be chapters (which contain
    #     pages), units (which contain chapters; units are not in every book), or the "root" part
    #     of which each book has exactly one.
    #
    # ******************************************************************************************

    # def pages
    #   @pages ||= begin
    #     page_ids = recursive_flatten_page_ids(data['tree']['contents'])
    #     Rails.logger.info "OpenSearch: found #{page_ids.count} possible page_ids in book #{@uuid}@#{@version}"

    #     pages = page_ids.map do |page_id|
    #       begin
    #         response = fetch_cnx_url(page_uri(page_id))

    #         Page.new(id: page_id,
    #                  data: JSON.parse(response.body),
    #                  desired_page_elements: @indexing_strategy.desired_page_elements)
    #       rescue => ex
    #         # TODO record data on a book's parsing
    #         #   * of page parsing failures and page uris
    #         #   * of page successes
    #         #   * avg time spent parsing a page (or maybe just the time for total book's pages)
    #         #   * send to Sentry
    #       end
    #     end.compact

    #     Rails.logger.info "OpenSearch: Loaded book #{@uuid}@#{@version} of #{pages.count} pages"
    #     pages
    #   end
    # end

    # private

    # def recursive_flatten_page_ids(contents, page_ids = [])
    #   contents.each do |chapter_or_unit|
    #     if chapter_or_unit.has_key?('contents')
    #       recursive_flatten_page_ids(chapter_or_unit['contents'], page_ids)
    #     else
    #       page_ids << chapter_or_unit['id']
    #     end
    #   end
    #   page_ids
    # end

    # def data
    #   @data ||= begin
    #     response = fetch_cnx_url(book_uri)
    #     JSON.parse(response.body)
    #   end
    # end

    # def page_uri(page_id)
    #   URI("#{CNX_URL_PREFIX}/#{@uuid}@#{@version}:#{page_id}.json")
    # end

    # def book_uri
    #   URI("#{CNX_URL_PREFIX}/#{@uuid}@#{@version}.json")
    # end

    # def fetch_cnx_url(uri)
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = (uri.scheme == "https")
    #   request = Net::HTTP::Get.new(uri.path)

    #   response = http.request(request)

    #   if response.code.to_i >= 400
    #     Rails.logger.debug "OpenSearch (error): book (#{@uuid}@#{@version}), uri #{uri}, error code: #{response.code}"
    #     raise "OpenSearch Unable to find Uri #{uri} #{response.code}"
    #   end

    #   response
    # end
  end
end
