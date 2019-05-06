# CreateIndexJob represents the value object of data
# sent to a worker that will index this search index
class CreateIndexJob < BaseJob
  attr_reader :book_version_id, :indexing_version

  def initialize(book_version_id:, indexing_version:)
    super()
    @book_version_id = book_version_id
    @indexing_version = indexing_version
  end
end
