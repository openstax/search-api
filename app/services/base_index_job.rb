class BaseIndexJob
  attr_reader :indexing_version,
              :book_version_id,
              :type

  def initialize(book_version_id:, indexing_version:)
    unless ACTIVE_INDEXING_VERSIONS.include?(indexing_version)
      raise InvalidIndexingVersion
    end

    @type = self.class.to_s
    @book_version_id = book_version_id
    @indexing_version = indexing_version

    @book_guid, @book_version = @book_version_id.split('@')
  end

  class InvalidIndexingVersion < StandardError
  end

  protected

  def indexer
    @indexer ||= Search::BookVersions::Index.new(book_guid: @book_guid,
                                                book_version: @book_version)
  end
end
