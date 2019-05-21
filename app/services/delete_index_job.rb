class DeleteIndexJob < BaseIndexJob
  def self.build_object(body:, when_completed_proc:)
    new(book_version_id: body[:book_version_id],
        indexing_strategy_name: body[:indexing_strategy_name],
        when_completed_proc: when_completed_proc)
  end

  def call
    index.delete
  end

  def as_json(*)
    {
      type: type,
      book_version_id: book_version_id,
      indexing_strategy_name: indexing_strategy_name
    }
  end
end
