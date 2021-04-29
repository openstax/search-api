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

  def basic
    {
      env_name: env_name,
      ami_id: ami_id,
      git_sha: git_sha
    }
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
    filtered_es_indices
    dynamo_books
    result = @book_indexes.map{|k,v| v.merge(id: k)}
    result.sort_by{|book_index| book_index[:id]}
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

  def filtered_es_indices
    es_indices = all_es_indices.stats["indices"]
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
    index = all_es_indices.get(index: index_name)
    es_created_at_ms = index[index_name]["settings"]["index"]["creation_date"]
    Time.at(es_created_at_ms.to_i/1000).utc.iso8601
  end

  def all_es_indices
    @all_es_indices ||= OsElasticsearchClient.instance.indices
  end

  def update_stat(index:, value_sym:, value:)
    stat = @book_indexes.fetch(index, DEFAULT_INFO.dup)
    stat[value_sym] = value
    @book_indexes[index] = stat
  end

  def env_name
    ENV['ENV_NAME'] || 'Not set'
  end

  def ami_id
    ENV['AMI_ID'] || 'Not set'
  end

  def git_sha
    `git show --pretty=%H -q`&.chomp || 'Not set'
  end
end
