class DoneIndexJob < BaseIndexJob
  attr_reader :results

  def self.build_object(body:, when_completed_proc:)
    new(results: body[:results],
        book_version_id: body[:book_version_id],
        indexing_version: body[:indexing_version],
        when_completed_proc: when_completed_proc)
  end

  def initialize(results:, **opts)
    super(opts)
    @results = results
  end

  def call
    # add anything here that gets done when this done job is processed
  end

  def as_json(*)
    {
      type: type,
      book_version_id: book_version_id,
      indexing_version: indexing_version,
      results: results
    }
  end

  class Results
    attr_reader :status, :es_stats, :time_took, :message

    STATUS = [
      STATUS_SUCCESSFUL               = "successful",
      STATUS_INVALID_INDEXING_VERSION = "invalid indexing version",
      STATUS_OTHER_ERROR              = "other error"
    ]

    def initialize(status: STATUS_SUCCESSFUL, time_took: nil, es_stats: nil, message: nil)
      @status = status
      @es_stats = es_stats
      @message = message
      @time_took = time_took
    end

    def as_json(*)
      {
        status: status,
        es_status: es_stats,
        time_took: time_took,
        message: message
      }
    end
  end
end
