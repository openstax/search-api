class BaseIndexJob
  attr_reader :indexing_strategy_name,
              :book_version_id,
              :type

  def self.build_object(params:, cleanup_after_call: nil)
    new(book_version_id:        params[:book_version_id],
        indexing_strategy_name: params[:indexing_strategy_name],
        cleanup_after_call:     cleanup_after_call)
  end

  def initialize(book_version_id: nil,
                 indexing_strategy_name: nil,
                 cleanup_after_call: nil)
    @cleanup_after_call = cleanup_after_call

    @type = self.class.to_s
    @book_version_id = book_version_id
    @indexing_strategy_name = indexing_strategy_name
  end

  def cleanup_after_call
    @cleanup_after_call.try(:call)
  end

  def cleanup_when_done
  end

  def remove_associated_book_index
    book_index = find_associated_book_index
    book_index.destroy!
  end

  def metadata
    internal_data = JSON.parse(to_json)
    book_index = find_associated_book_index
    internal_data.merge(JSON.parse((book_index || {}).to_json))
  end

  def find_associated_book_index
    BookIndexState.where(book_version_id: book_version_id,
                         indexing_strategy_name: indexing_strategy_name).first
  end

  def index
    @index ||= Search::BookVersions::Index.new( book_version: @book_version_id)
  end
end
