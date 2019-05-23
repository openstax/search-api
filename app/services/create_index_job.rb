class CreateIndexJob < BaseIndexJob
  def call
    index.recreate
  end

  def cleanup_when_done
    book_index = find_associated_book_index
    book_index.mark_created
  end

  def as_json(*)
    {
      type: type,
      book_version_id: book_version_id,
      indexing_strategy_name: indexing_strategy_name
    }
  end
end
