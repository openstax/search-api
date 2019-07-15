module Api::V0::Swagger::Models::Stat
  include Swagger::Blocks
  include OpenStax::Swagger::SwaggerBlocksExtensions

  swagger_schema :StatBookIndexResult do
    key :required, [:id, :num_docs]
    property :id do
      key :type, :string
      key :readOnly, true
      key :description, "The ID of the book"
    end
    property :num_docs do
      key :type, :string
      key :readOnly, true
      key :description, "The num of docs in the index"
    end
    property :state do
      key :type, :string
      key :readOnly, true
      key :description, "The state of the index"
    end
  end

  swagger_schema :StatResults do
    key :required, [:overall_took, :es_version]
    property :overall_took_ms do
      key :type, :integer
      key :readOnly, true
      key :description, "How long the request took (ms)"
    end
    property :es_version do
      key :type, :string
      key :readOnly, true
      key :description, "Current version of Elasticsearch"
    end
    property :book_indexes do
      key :type, :array
      key :description, "The book indexes"
      items do
        key :'$ref', :StatBookIndexResult
      end
    end
  end
end
