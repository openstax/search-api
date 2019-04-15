class BookIndexing
  include Dynamoid::Document

  VALID_STATES = [
    PENDING = "pending",
    DELETE_PENDING = "delete pending",
    STARTED = "started",
    INDEXED = "indexed",
    DELETED = "deleted"
  ]
  VALID_INDEXING_STRATEGIES = %w(I1)

  validates :state, inclusion: { in: VALID_STATES }
  validates :indexing_version, inclusion: { in: VALID_INDEXING_STRATEGIES }

  field :state
  field :book_version_id
  field :indexing_version
  field :enqueued_time, :datetime, store_as_string: true
  field :started_time,  :datetime, store_as_string: true
  field :finished_time, :datetime, store_as_string: true
  field :message

  def initialize
    self.in_demand = false
  end

  # #create is used to add a book indexing dynamoid document to represent
  # the enqueueing of a "job" to the SQS indexing pipeline
  def self.create(book_version_id:, indexing_version:, state: PENDING)
    Rails.logger.info "Creating book version #{@book_version_id} #{@indexing_version} in dynamodb"

    BookIndexing.new.tap do |job|
      job.state = state
      job.book_version_id = book_version_id
      job.indexing_version = indexing_version
      job.enqueued_time = DateTime.now
      job.save!
    end
  end

  def self.valid_book_indexings
    where('state.not_contains': [DELETE_PENDING, DELETED])
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
