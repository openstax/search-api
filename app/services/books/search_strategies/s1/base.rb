module Books::SearchStrategies::S1
  class Base

    def initialize(index_names:)
      @index_names = index_names
    end

    def search(query_string:)
      OsElasticsearchClient.instance.search(
        index: @index_names.join(','),
        body: search_body(query_string).to_json
      )
    end

    protected

    def search_body(query_string)
      raise "Implement `search_body` in the child class!"
    end

  end
end
