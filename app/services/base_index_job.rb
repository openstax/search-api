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

  def call
    _call
  ensure #it should always remove the job from the queue
    @cleanup_after_call.try(:call)
  end

  def cleanup_when_done
  end

  def to_hash
    JSON.parse(to_json).with_indifferent_access
  end

  def remove_associated_book_index_state
    book_index_state = find_associated_book_index_state
    book_index_state&.destroy!
  end

  def inspect
    to_hash.merge((find_associated_book_index_state || {}).to_hash)
  end

  def find_associated_book_index_state
    BookIndexState.where(book_version_id: book_version_id,
                         indexing_strategy_name: indexing_strategy_name).first
  end

  def index
    @index ||= Books::Index.new(book_version_id: @book_version_id)
  end

  def cleanup_after_call
    @cleanup_after_call.try(:call)
  end

  private

  def _call
    raise "Implement _call in any derived class!"
  end
end
