# BookIndexState represents the dynamodb documents ORM
#
# PK (used for internal sharding) is:
#    hash_key: book_version_id + range_key: indexing_version
#
# To created this table in development, run:  rake dynamoid:create_tables
class BookIndexState
  include Dynamoid::Document

  table name: Rails.application.secrets.dynamodb[:index_state_table_name].parameterize.underscore.to_sym,
        key: :book_version_id

  range :indexing_version

  field :state
  # todo replace these timestamp fields with a status log
  field :enqueued_time, :datetime, store_as_string: true

  field :updated_at,    :datetime, store_as_string: true
  field :created_at,    :datetime, store_as_string: true
  field :message

  STATES                  = [
    STATE_CREATE_PENDING = "create pending",
    STATE_DELETE_PENDING = "delete pending",
    STATE_CREATED = "created",
    STATE_DELETED = "deleted"
  ]
  VALID_INDEXING_VERSIONS = %w(I1)

  validates :state, inclusion: { in: STATES }
  validates :indexing_version, inclusion: { in: VALID_INDEXING_VERSIONS }

  attr_accessor :in_demand

  def self.create(book_version_id:, indexing_version:, state: STATE_CREATE_PENDING)
    new.tap do |job|
      job.state = state
      job.book_version_id = book_version_id
      job.indexing_version = indexing_version
      job.enqueued_time = DateTime.now
      job.save!
    end
  end

  def self.live
    all.reject{ |doc| doc.deleting? }
  end

  def initialize(*args)
    super
    self.in_demand = false
  end

  def mark_queued_for_deletion
    self.state = STATE_DELETE_PENDING
    self.enqueued_time = DateTime.now
    save!
  end

  def deleting?
    [STATE_DELETED, STATE_DELETE_PENDING].include?(self.state)
  end

  private :initialize
end
