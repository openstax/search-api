module Api::V0::Swagger::Models::Search
  include Swagger::Blocks
  include OpenStax::Swagger::SwaggerBlocksExtensions

  SUPPORTED_ELEMENT_TYPES = [
    Books::IndexingStrategies::I1::ParagraphDocument,
    Books::IndexingStrategies::I1::FigureDocument,
    Books::IndexingStrategies::I1::KeyTermDocument
  ].map(&:element_type)

  swagger_schema :SearchResultHitHighlight do
    key :required, [:visible_content]
    property :visible_content do
      key :type, :array
      key :description, "The highlights in visible content"
      items do
        key :type, :string
        key :readOnly, true
        key :description, "A highlight"
      end
    end
    property :title do
      key :type, :string
      key :readOnly, true
      key :description, "The title of this element."
    end
  end

  swagger_schema :SearchResultHitSource do
    key :required, [:page_id, :element_type, :element_id, :page_position]
    property :page_id do
      key :type, :string
      key :readOnly, true
      key :description, "The page UUID@version containing the hit"
    end
    property :element_type do
      key :type, :string
      key :readOnly, true
      key :enum, SUPPORTED_ELEMENT_TYPES
      key :description, "The element type of the hit.  One of #{SUPPORTED_ELEMENT_TYPES}"
    end
    property :element_id do
      key :type, :string
      key :readOnly, true
      key :description, "The element id of the hit."
    end
    property :page_position do
      key :type, :integer
      key :readOnly, true
      key :description, "A number used to sort element hits within one page"
    end
  end

  swagger_schema :SearchResultHit do
    key :required, [:_index, :_score, :_source, :highlight]
    property :_index do
      key :type, :string
      key :readOnly, true
      key :description, "The name of the index from which the hit came"
    end
    property :_score do
      key :type, :number
      key :format, :float
      key :readOnly, true
      key :description, "The hit's score"
    end
    property :_source do
      key :'$ref', :SearchResultHitSource
    end
    property :highlight do
      key :'$ref', :SearchResultHitHighlight
    end
  end

  swagger_schema :SearchResult do
    key :required, [:overall_took, :took, :timed_out, :_shards, :hits]
    property :overall_took do
      key :type, :integer
      key :readOnly, true
      key :description, "How long the request took inside Open-Search, including ES 'took' (ms)"
    end
    property :took do
      key :type, :integer
      key :readOnly, true
      key :description, "How long the request took inside Elasticsearch (ms)"
    end
    property :timed_out do
      key :type, :boolean
      key :readOnly, true
      key :description, "Whether the request in Elasticsearch timed out"
    end
    property :_shards do
      key :type, :object
      key :readOnly, true
      key :description, "Shard stats from Elasticsearch"
    end
    property :hits do
      key :required, [:total, :hits]
      property :total do
        key :type, :integer
        key :readOnly, true
        key :description, "The number of hits"
      end
      property :max_score do
        key :type, :number
        key :format, :float
        key :readOnly, true
        key :description, "The largest hit score"
      end
      property :hits do
        key :type, :array
        key :description, "Elasticsearch search hits"
        items do
          key :'$ref', :SearchResultHit
        end
      end
    end
  end
end
