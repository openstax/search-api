class CreateIndexJob < BaseIndexJob
  def cleanup_when_done
    book_index_state = find_associated_book_index_state
    book_index_state&.mark_created
  end

  def as_json(*)
    {
      type: type,
      book_version_id: book_version_id,
      indexing_strategy_name: indexing_strategy_name
    }
  end

  private

  def _call
    index.recreate
  end
end
