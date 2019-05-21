class BaseIndexJob
  attr_reader :indexing_strategy_name,
              :book_version_id,
              :type

  def initialize(book_version_id:, indexing_strategy_name:, when_completed_proc: nil)
    @when_completed_proc = when_completed_proc

    @type = self.class.to_s
    @book_version_id = book_version_id
    @indexing_strategy_name = indexing_strategy_name

    @book_uuid, @book_version = @book_version_id.split('@')
  end

  def when_completed
    @when_completed_proc.try(:call)
  end

  protected

  def index
    @index ||= Search::BookVersions::Index.new(book_guid:    @book_uuid,
                                               book_version: @book_version)
  end
end
