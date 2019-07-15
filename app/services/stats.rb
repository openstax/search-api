class Stats
  DEFAULT_STAT = {
    state:"not found!",
    num_docs: "not found!"
  }
  BOOK_INDEX_MATCH = /[\w-]+@\w+.+_+.+/

  def initialize
    @book_indexes = {}
  end

  def call
    results
  end

  private

  def results
    {
      es_version: es_version,
      book_indexes: load_all_the_books
    }
  end

  def es_version
    OsElasticsearchClient.instance.info["version"]["number"]
  end

  def load_all_the_books
    load_es_indices
    load_dynamo_books

    @book_indexes.each_with_object([]) do |(k,v), arr|
      arr << {
        id: k,
        num_docs: v[:num_docs],
        state: v[:state]
      }
    end
  end

  def load_dynamo_books
    books = BookIndexState.all
    books.each do |book|
      update_stat(index: "#{book.book_version_id}_#{book.indexing_strategy_name}".downcase,
                   value_sym: :state,
                   value: book.state)
    end
  end

  def load_es_indices
    es_indices = OsElasticsearchClient.instance.indices.stats["indices"]
    es_indices.each do |es_index|
      if BOOK_INDEX_MATCH.match?(es_index.first)
        update_stat(index: es_index.first,
                    value_sym: :num_docs,
                    value: es_index.second["primaries"]["docs"]["count"])
      end
    end
  end

  def update_stat(index:, value_sym:, value:)
    stat = @book_indexes.fetch(index, DEFAULT_STAT.dup)
    stat[value_sym] = value
    @book_indexes[index] = stat
  end
end
