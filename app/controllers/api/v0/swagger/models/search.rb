module Api::V0::Swagger::Models::Search
  include Swagger::Blocks
  include OpenStax::Swagger::SwaggerBlocksExtensions

  swagger_schema :SearchResult do
    property :raw_results do
      key :type, :object
      key :readOnly, true
      key :description, "The raw search results from Elasticsearch"
    end
  end
end
