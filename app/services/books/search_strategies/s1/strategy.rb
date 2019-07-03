module Books::SearchStrategies::S1
  class Strategy < Base

    SUPPORTED_INDEX_STRATEGIES = [
      Books::IndexingStrategies::I1::Strategy
    ].map(&:short_name)

    MAX_SEARCH_RESULTS = 150

    def self.short_name
      "s1"
    end

    def initialize(index_names:, options: {})
      super(index_names: index_names)
    end

    def self.supports_index_strategy?(name)
      SUPPORTED_INDEX_STRATEGIES.include?(name.downcase)
    end

    protected

    def search_body(query_string)
      # query_string = single_quotes_to_double(query_string)

      {
        size: MAX_SEARCH_RESULTS,
        query: {
          simple_query_string: {
            fields: %w(title visible_content),
            query: query_string,
            flags: "WHITESPACE|PHRASE",
            minimum_should_match: "100%",
            default_operator: "AND"
          }
        },
        _source: %w(element_type element_id page_id page_position),
        highlight: {
          number_of_fragments: 20,
          fields: {
            title: {},
            visible_content: {}
          }
        }
      }
    end

  end
end
