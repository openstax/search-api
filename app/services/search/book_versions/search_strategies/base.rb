module Search::BookVersions::SearchStrategies
  class Base

    attr_reader :name

    def initialize(name:, index_name:)
      @index_name
    end

    def search(query_string:)
      OpenSearch::ElasticsearchClient.instance.search(
        body: search_body(query_string).to_json
      )
    end

    protected

    def search_body(query_string)
      raise "Implement `search_body` in the child class!"
    end

  end
end
