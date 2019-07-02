module Books::SearchStrategies::S1
  class UnknownSearchStrategy < StandardError
    def initialize(search_strategy)
      super("Unknown search strategy: #{search_strategy}")
    end
  end
end
