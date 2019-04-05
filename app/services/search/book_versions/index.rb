module Search::BookVersions
  # Search::BookVersions::Index is the main interface into indexing a book version.
  #
  # It uses a IndexingStrategy that defines what is indexed including the
  # index's metadata.
  #
  # This class performs the "crud" actions on a book's index.
  class Index
    DEFAULT_INDEXING_STRATEGY = I1::IndexingStrategy

    attr_reader :indexing_strategy

    def initialize(book_guid:,
                   book_version:,
                   indexing_strategy: DEFAULT_INDEXING_STRATEGY)
      @book_guid = book_guid
      @book_version = book_version
      @indexing_strategy = indexing_strategy.new
    end

    def create
      ElasticsearchClient.instance.indices.create(index: index_name, body: @indexing_strategy.index_metadata)
    rescue => ex
      Rails.logger.error "OpenSearch (error): unable to create index for book #{index_name}: #{ex.message}"
    end

    # This method populates the index with data from the book version.
    def populate
      starting = Time.now

      book = Openstax::Book.new(uuid: @book_guid,
                                version: @book_version)

      @indexing_strategy.index(book: book)

      time_took = Time.at(Time.now - starting).utc.strftime("%H:%M:%S")
      Rails.logger.info("OpenSearch: Indexing book #{index_name} took #{time_took} time")
    rescue => ex
      # TODO record data on a book's indexing
      #   * indexing time spent for book
      #   * indexing failure if any
      #   * send to Sentry
      Rails.logger.error "OpenSearch (error): Unable to index book #{index_name}: #{[ex.message, *ex.backtrace].join($/)}"
      # raise custom exception OpenSearchIndexingFailed?
    end

    def recreate
      delete
      create
      populate
    end

    def delete
      ElasticsearchClient.instance.indices.delete(index: index_name)
    rescue => ex
      Rails.logger.error "OpenSearch (error): Unable to delete index for book #{index_name}: #{ex.message}"
    end

    def name
      "#{@book_guid}@#{@book_version}_#{@indexing_strategy.version.downcase}"
    end
  end
end
