module Search::BookVersions::SearchStrategies
  class Factory

    STRATEGY_CLASSES = [
      S1
    ].freeze

    NAMES_TO_STRATEGY_CLASSES = STRATEGY_CLASSES.each_with_object({}) do |klass, hash|
      hash[klass.name.downcase] = klass
    end.freeze

    def self.build(book_version_id:, index_strategy:, search_strategy:, options: {})
      book_guid, book_version = book_version_id.split('@')
      @index = Index.new(book_guid: book_guid, book_version: book_version)

      strategy_class = NAMES_TO_STRATEGY_CLASSES[search_strategy.downcase]

      if strategy_class.nil?
        raise "Unknown search strategy: #{search_strategy}"
      end

      if !strategy_class.supports_index_strategy?(index_strategy)
        raise "Search strategy #{search_strategy} does not support index strategy #{index_strategy}"
      end

      strategy_class.new(index_name: @index.name, options: options)
    end

  end
end
