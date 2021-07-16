module Books
  # Books::Index is the main interface into indexing a book.
  #
  # It uses a IndexingStrategy that defines what is indexed including the
  # index's inspect.
  #
  # This class performs the "crud" actions on a book's index.
  class Index
    prefix_logger "Books::Index"

    DEFAULT_INDEXING_STRATEGY = IndexingStrategies::I1::Strategy
    URL_BASE = "https://openstax.org"
    RAP_URL_BASE = "#{URL_BASE}/apps/archive"
    LEGACY_URL_BASE = "#{URL_BASE}/contents"

    class IndexResourceNotReadyError < StandardError; end

    WAIT_UNTIL_MAX_TRIES = 30
    WAIT_UNTIL_TRIES_INTERVAL_SEC = 2

    attr_reader :indexing_strategy

    delegate :index_name, to: :class

    def self.index_name(book_version_id:, indexing_strategy_short_name:)
      "#{book_version_id}_#{indexing_strategy_short_name.downcase}"
    end

    def initialize(book_version_id: nil,
                   indexing_strategy: DEFAULT_INDEXING_STRATEGY)
      @book_version_id = book_version_id
      @indexing_strategy = indexing_strategy.new
    end

    def create(with_wait: true)
      log_debug("create #{name} called")
      OsElasticsearchClient.instance.indices.create(index: name,
                                                    body: @indexing_strategy.index_metadata)
      wait_until(:exists?) if with_wait
    end

    # This method populates the index with pages from the book
    def populate
      log_debug("populate #{name} called")
      @indexing_strategy.index(book: book, index_name: name)

      index_stats
    end

    def recreate
      delete rescue Elasticsearch::Transport::Transport::Errors::NotFound
      create
      populate
    end

    def delete(with_wait: true)
      log_debug("delete #{name} called")
      OsElasticsearchClient.instance.indices.delete(index: name)
      wait_until(:not_exists?) if with_wait
    end

    def name
      index_name(book_version_id: @book_version_id,
                 indexing_strategy_short_name: @indexing_strategy.short_name)
    end

    def exists?
      OsElasticsearchClient.instance.indices.exists?(index: name)
    end

    def not_exists?
      !OsElasticsearchClient.instance.indices.exists?(index: name)
    end

    private

    def wait_until(this_happens)
      tries = 1
      until self.send(this_happens) || tries > WAIT_UNTIL_MAX_TRIES  do
        log_debug("Waiting #{WAIT_UNTIL_TRIES_INTERVAL_SEC} secs for #{name} to #{this_happens.to_s}, num_tries so far: #{tries}")
        sleep(WAIT_UNTIL_TRIES_INTERVAL_SEC)
        tries += 1
      end

      if tries >= WAIT_UNTIL_MAX_TRIES
        raise IndexResourceNotReadyError.new("Books::Index. #{name}:#{this_happens.to_s} failed after #{tries} tries.")
      end

      log_debug("Exiting waiting for #{name} to #{this_happens.to_s} after tries: #{tries}")
    end

    def indices
      @indices ||= OsElasticsearchClient.instance.indices
    end

    def index_stats
      es_stats = OsElasticsearchClient.instance.indices.stats(index: name)
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
        pipeline_version, uuid_at_number = @book_version_id.split('/')

        archive_url = pipeline_version == "legacy" ? LEGACY_URL_BASE : RAP_URL_BASE

        OpenStax::Cnx::V1.with_archive_url(archive_url) do
          OpenStax::Cnx::V1::Book.new(id: uuid_at_number)
        end
      end
    end
  end
end
