# BookIndexState represents the dynamodb documents ORM
#
# PK (used for internal sharding) is:
#    hash_key: book_version_id + range_key: indexing_version
#
# To created this table in development, run:  rake dynamoid:create_tables
class BookIndexState
  include Dynamoid::Document

  class Status
    ACTIONS = [
      ACTION_CREATED = 'enqueued_created',
      ACTION_DELETED = 'enqueued_deletion'
    ]

    attr_reader :action, :at

    def initialize(action:, at: DateTime.now)
      @action = action
      @at = at
    end

    def dynamoid_dump
      {
        action: @action,
        at: @at
      }.to_json
    end

    def self.dynamoid_load(serialized_str)
      values = JSON.parse(serialized_str)
      new(action: values['action'], at: values['at'])
    end
  end

  table name: Rails.application.secrets.dynamodb[:index_state_table_name].parameterize.underscore.to_sym,
        key: :book_version_id

  range :indexing_version

  field :state
  field :status_log,:array,     of: Status
  field :updated_at,:datetime,  store_as_string: true
  field :created_at,:datetime,  store_as_string: true
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
    new.tap do |boo_index_state|
      boo_index_state.state = state
      boo_index_state.book_version_id = book_version_id
      boo_index_state.indexing_version = indexing_version
      new_status = Status.new(action: Status::ACTION_CREATED)
      boo_index_state.status_log = [ new_status ]
      boo_index_state.save!
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
    self.status_log << Status.new(action: Status::ACTION_DELETED)
    save!
  end

  def deleting?
    [STATE_DELETED, STATE_DELETE_PENDING].include?(self.state)
  end

  private :initialize
end
