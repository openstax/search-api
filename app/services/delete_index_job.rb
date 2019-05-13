class DeleteIndexJob < BaseIndexJob
  def self.build_object(body:, when_completed_proc:)
    new(book_version_id: body[:book_version_id],
        indexing_version: body[:indexing_version],
        when_completed_proc: when_completed_proc)
  end

  def call
    index.delete
  end

  def as_json(*)
    {
      type: type,
      book_version_id: book_version_id,
      indexing_version: indexing_version
    }
  end
end
