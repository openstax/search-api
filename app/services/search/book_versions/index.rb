module Search::BookVersions
  # Search::BookVersions::Index is the main interface into indexing a book version.
  #
  # It uses a IndexingStrategy that defines what is indexed including the
  # index's inspect.
  #
  # This class perf gueorms the "crud" actions on a book's index.
  class Index
    DEFAULT_INDEXING_STRATEGY = I1::IndexingStrategy

    attr_reader :indexing_strategy

    def initialize(book_version_id: nil,
                   indexing_strategy: DEFAULT_INDEXING_STRATEGY)
      @book_version_id = book_version_id
      @indexing_strategy = indexing_strategy.new
    end

    def create
      OpenSearch::ElasticsearchClient.instance.indices.create(index: name, body: @indexing_strategy.index_metadata)
    end

    # This method populates the index with pages from the book
    def populate
      @indexing_strategy.index(book: book, index_name: name)

      index_stats
    end

    def recreate
      delete rescue Elasticsearch::Transport::Transport::Errors::NotFound
      create
      populate
    end

    def delete
      OpenSearch::ElasticsearchClient.instance.indices.delete(index: name)
    end

    def name
      "#{@book_version_id}_#{@indexing_strategy.version.downcase}"
    end

    private

    def indices
      @indices ||= OpenSearch::ElasticsearchClient.instance.indices
    end

    def index_stats
      es_stats = OpenSearch::ElasticsearchClient.instance.indices.stats(index: name)
      {
        num_docs_in_index: es_stats["indices"][name]['primaries']['docs']['count'],
        index_name: name
        # todo more stats?
      }
    end

    def get_version
      book.version
    end

    def book
      @book ||= begin
        OpenStax::Cnx::V1::Book.new(id: @book_version_id)
      end
    end
  end
end
