module Search::BookVersions::SearchStrategies
  class IncompatibleStrategies < StandardError
    def initialize(search_strategy:, index_strategy:)
      super("Search strategy #{search_strategy} does not support index strategy #{index_strategy}")
    end
  end
end
