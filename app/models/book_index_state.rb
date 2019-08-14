# BookIndexState represents the dynamodb documents ORM
#
# PK (used for internal sharding) is:
#    hash_key: book_version_id + range_key: indexing_strategy_name
#
# To created this table in development, run:  rake dynamoid:create_tables
class BookIndexState
  include Dynamoid::Document

  class StatusLog
    ACTIONS = [
      ACTION_CREATE  = 'enqueued create',
      ACTION_CREATED = 'index created',
      ACTION_INDEX_ERROR   = 'index error',
      ACTION_HTTP_ERROR    = 'http error',
      ACTION_DELETE_PENDING = "index delete pending"
    ]

    attr_reader :action, :at

    def initialize(action:, at: DateTime.now)
      @action = action
      @at = at
    end

    def dynamoid_dump
      {
        action: @action,
        at: @at.utc
      }.to_json
    end

    def self.dynamoid_load(serialized_str)
      values = JSON.parse(serialized_str)
      new(action: values['action'], at: DateTime.parse(values['at']))
    end
  end

  table name: Rails.application.secrets.dynamodb[:index_state_table_name],
        key: :book_version_id

  range :indexing_strategy_name

  field :state
  field :status_log, :array, of: StatusLog
  field :updated_at, :datetime, store_as_string: true
  field :created_at, :datetime, store_as_string: true
  field :message

  STATES = [
    STATE_CREATE_PENDING = "create pending",
    STATE_DELETE_PENDING = "delete pending",
    STATE_HTTP_ERROR = "http error",
    STATE_CREATED = "created"
  ]
  VALID_INDEXING_STRATEGY_NAMES = %w(I1)

  validates :state, inclusion: { in: STATES }
  validates :indexing_strategy_name, inclusion: { in: VALID_INDEXING_STRATEGY_NAMES }

  attr_accessor :in_demand

  def self.create(book_version_id:, indexing_strategy_name:, state: STATE_CREATE_PENDING)
    new(
      state: state,
      book_version_id: book_version_id,
      indexing_strategy_name: indexing_strategy_name,
      status_log: [StatusLog.new(action: StatusLog::ACTION_CREATE)]
    ).save!
  end

  def self.live
    all.reject{ |doc| doc.deleting? }
  end

  def self.created
    live.select{ |doc| doc.created? }
  end

  def initialize(*args)
    super
    self.in_demand = false
  end

  def mark_created
    self.state = STATE_CREATED
    self.status_log << StatusLog.new(action: StatusLog::ACTION_CREATED)
    save!
  end

  def mark_as_http_error
    self.state = STATE_HTTP_ERROR
    self.status_log << StatusLog.new(action: StatusLog::ACTION_HTTP_ERROR)
    self.status_log << StatusLog.new(action: StatusLog::ACTION_INDEX_ERROR)
    save!
  end

  def mark_queued_for_deletion
    self.state = STATE_DELETE_PENDING
    self.status_log << StatusLog.new(action: StatusLog::ACTION_DELETE_PENDING)
    save!
  end

  def deleting?
    [STATE_DELETE_PENDING].include?(self.state)
  end

  def created?
    [STATE_CREATED].include?(self.state)
  end

  def to_hash
    JSON.parse(to_json).with_indifferent_access
  end

  private :initialize
end
