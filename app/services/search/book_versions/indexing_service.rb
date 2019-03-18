module Search::BookVersions
  class IndexingService
    DEFAULT_INDEXING_VERSION = I1::IndexMapping

    def initialize(book_guid:,
                   book_version:,
                   indexing_mapping: DEFAULT_INDEXING_VERSION)
      @book_guid = book_guid
      @book_version = book_version
      @index_mapping = indexing_mapping.new
    end

    def create_index
      ElasticsearchClient.instance.indices.create(index: index_name, body: @index_mapping.index_metadata)
    end

    def add_book_pages_to_search_index
      starting = Time.now

      book = Openstax::Book.new(uuid: @book_guid, version: @book_version)
      book.pages.each do |page|
        page.indexable_elements.each do |element|
          ElasticsearchClient.instance.index(index: index_name,
                                             type: Search::BookVersions::I1::PageElementType.index_type,
                                             body: element.to_h)
        end
      end

      ending = Time.now
      time_took = Time.at(ending - starting).utc.strftime("%H:%M:%S")
      Rails.logger.info("Indexing book #{index_name} #{book.pages.count} pages took #{time_took} time")
    # rescue
      # exceptions?
    end

    def reindex
      delete_index
      create_index
      add_book_pages_to_search_index
    end

    def delete_index
      ElasticsearchClient.instance.indices.delete(index: index_name)
    end

    private

    def index_name
      "#{@book_guid}@#{@book_version}_#{@index_mapping.strategy.downcase}"
    end
  end
end
