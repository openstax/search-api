module Search::BookVersions
  # Search::BookVersions::Index is the main interface into indexing a book version.
  #
  # It uses a IndexingStrategy that defines what is indexed including the
  # index's metadata.
  #
  # This class perf gueorms the "crud" actions on a book's index.
  class Index
    DEFAULT_INDEXING_STRATEGY = I1::IndexingStrategy

    attr_reader :indexing_strategy

    def initialize(book_guid:,
                   book_version: nil,
                   indexing_strategy: DEFAULT_INDEXING_STRATEGY)
      @book_guid = book_guid
      @book_version = book_version || get_version
      @indexing_strategy = indexing_strategy.new
    end

    def create
      OpenSearch::ElasticsearchClient.instance.indices.create(index: name, body: @indexing_strategy.index_metadata)
    end

    # This method populates the index with pages from the book
    def populate
      starting = Time.now

      @indexing_strategy.index(book: book, index_name: name)

      time_took = Time.at(Time.now - starting).utc.strftime("%H:%M:%S")
      Rails.logger.info("OpenSearch: Indexing book index #{name} took #{time_took} time")
    end

    def recreate
      delete
      create
      populate
    end

    def delete
      OpenSearch::ElasticsearchClient.instance.indices.delete(index: name)
    end

    def name
      "#{@book_guid}@#{@book_version}_#{@indexing_strategy.version.downcase}"
    end

    private
    def get_version
      book.version
    end

    def book
      @book ||= begin
        id = @book_version ? "#{@book_guid}@#{@book_version}" : @book_guid
        OpenStax::Cnx::V1::Book.new(id: id)
      end
    end
  end
end
