module Search::BookVersions::SearchStrategies
  class Factory

    STRATEGY_CLASSES = [
      S1
    ].freeze

    NAMES_TO_STRATEGY_CLASSES = STRATEGY_CLASSES.each_with_object({}) do |klass, hash|
      hash[klass.short_name.downcase] = klass
    end.freeze

    def self.build(book_version_ids:, index_strategy:, search_strategy:, options: {})
      index_names = book_version_ids.map do |book_version_id|
        index = Search::BookVersions::Index.new(book_version_id: book_version_id)
        index.name
      end

      strategy_class = NAMES_TO_STRATEGY_CLASSES[search_strategy.downcase]

      if strategy_class.nil?
        raise UnknownSearchStrategy, search_strategy
      end

      if !strategy_class.supports_index_strategy?(index_strategy)
        raise IncompatibleStrategies.new(search_strategy: search_strategy, index_strategy: index_strategy)
      end

      strategy_class.new(index_names: index_names, options: options)
    end

  end
end
