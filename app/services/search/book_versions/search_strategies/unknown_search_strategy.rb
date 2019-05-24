module Search::BookVersions::SearchStrategies
  class UnknownSearchStrategy < StandardError
    def initialize(search_strategy)
      super("Unknown search strategy: #{search_strategy}")
    end
  end
end
