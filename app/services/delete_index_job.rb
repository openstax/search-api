class DeleteIndexJob < BaseIndexJob
  def self.build_object(body)
    new(book_version_id: body[:book_version_id],
        indexing_version: body[:indexing_version])
  end

  def call
    indexer.delete
  end

  def as_json(*)
    {
      "type" => @type,
      "book_version_id" => @book_version_id,
      "indexing_version" => @indexing_version
    }
  end
end
