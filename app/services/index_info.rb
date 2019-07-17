class IndexInfo
  DEFAULT_INFO = {
    state:"not found",
    num_docs: "not found"
  }
  BOOK_INDEX_MATCH = /[\w-]+@\w+.+_+.+/

  def call
    @book_indexes = {}
    results
  end

  private

  def results
    {
      es_version: es_version,
      book_indexes: all_the_books
    }
  end

  def es_version
    OsElasticsearchClient.instance.info["version"]["number"]
  end

  def all_the_books
    es_indices
    dynamo_books
    @book_indexes.map{|k,v| v.merge(id: k)}
  end

  def dynamo_books
    books = BookIndexState.all
    books.each do |book|
      index_name = Books::Index.index_name(
        book_version_id: book.book_version_id,
        indexing_strategy_short_name: book.indexing_strategy_name)

      update_stat(index: index_name,
                  value_sym: :state,
                  value: book.state)
    end
  end

  def es_indices
    es_indices = OsElasticsearchClient.instance.indices.stats["indices"]
    es_indices.each do |es_index|
      index_name = es_index.first
      if BOOK_INDEX_MATCH.match?(index_name)
        update_stat(index: index_name,
                    value_sym: :num_docs,
                    value: es_index.second["primaries"]["docs"]["count"])

        update_stat(index: index_name,
                    value_sym: :created_at,
                    value: es_created_at(index_name))
      end
    end
  end

  def es_created_at(index_name)
    index = OsElasticsearchClient.instance.indices.get(index: index_name)
    es_created_at_ms = index[index_name]["settings"]["index"]["creation_date"]
    DateTime.strptime((es_created_at_ms.to_i/1000).to_s,'%s')
  end

  def update_stat(index:, value_sym:, value:)
    stat = @book_indexes.fetch(index, DEFAULT_INFO.dup)
    stat[value_sym] = value
    @book_indexes[index] = stat
  end
end
