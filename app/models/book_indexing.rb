# BookIndexing represents the dynamodb documents ORM
#
# PK (used for internal sharding) is:
#    hash_key: book_version_id + range_key: indexing_version
class BookIndexing
  include Dynamoid::Document

  table name: Rails.application.secrets.dynamodb[:index_state_table_name].parameterize.underscore.to_sym,
        key: :book_version_id

  range :indexing_version

  field :state
  field :enqueued_time, :datetime, store_as_string: true
  field :started_time,  :datetime, store_as_string: true
  field :finished_time, :datetime, store_as_string: true
  field :updated_at,    :datetime, store_as_string: true
  field :created_at,    :datetime, store_as_string: true
  field :message

  STATES = [
    STATE_PENDING = "pending",
    STATE_DELETE_PENDING = "delete pending",
    STATE_STARTED = "started",
    STATE_INDEXED = "indexed",
    STATE_DELETED = "deleted"
  ]
  VALID_INDEXING_STRATEGIES = %w(I1)

  validates :state, inclusion: { in: STATES }
  validates :indexing_version, inclusion: { in: VALID_INDEXING_STRATEGIES }

  attr_reader :in_demand

  def self.create_new_indexing(book_version_id:, indexing_version:)
    Rails.logger.info "Creating book version #{@book_version_id} #{@indexing_version} in dynamodb"

    new.tap do |job|
      job.state = STATE_PENDING
      job.book_version_id = book_version_id
      job.indexing_version = indexing_version
      job.enqueued_time = DateTime.now
      job.save!
    end
  end

  def self.live_book_indexings
    all.reject{ |doc| doc.deleting? }
  end

  def initialize(*args)
    super
    self.in_demand = false
  end

  def deleting?
    [STATE_DELETED, STATE_DELETE_PENDING].include?(self.state)
  end

  def queue_to_delete
    self.state = STATE_DELETE_PENDING
    self.enqueued_time = DateTime.now
    save!
  end

  # #save is used to update a book indexing dynamoid document to represent
  # the actual processing of a "job" in the SQS indexing pipeline
  def start(book_version_id:)
  end

  # #finish is used to update a book indexing dynamoid document to represent
  # the completion a "job" in the SQS indexing pipeline
  def finish(book_version_id:)
  end

  def in_demand=(value)
    @in_demand = value
  end
end
