module Search::BookVersions::SearchStrategies
  class S1 < Base

    SUPPORTED_INDEX_STRATEGIES = %w(i1)

    def initialize(index_name:, options: {})
      super(index_name: index_name, name: "s1")
    end

    def self.supports_index_strategy?(name)
      SUPPORTED_INDEX_STRATEGIES.include?(name.downcase)
    end

    protected

    def search_body(query_string)
      {
        "size": 25,
        "query": {
          "multi_match": {
            "query": query_string
          }
        },
        "_source": ["id"],
        "highlight": {
          "fields": {
            "content": {}
          }
        }
      }
    end

  end
end
