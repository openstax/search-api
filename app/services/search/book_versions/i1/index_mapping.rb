module Search::BookVersions::I1
  class IndexMapping
    INDEXING_STRATEGY = "I1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1
    ELEMENT_TYPE_MAPPINGS = [
      Search::BookVersions::I1::PageElementType,
    ]

    attr_reader :strategy

    def initialize
      @strategy = INDEXING_STRATEGY
    end

    def index_metadata
      @index_meta ||= begin
        metadata_hashes = [settings, mappings]
        metadata_hashes.inject({}) { |aggregate, hash| aggregate.merge! hash }
      end
    end

    private

    def settings
      {
        settings: {
          index: {
            number_of_shards: NUM_SHARDS,
            number_of_replicas: NUM_REPLICAS
          },
          analysis: {
            analyzer: :simple
          }
        }
      }
    end

    def mappings
      { mappings: {} }.merge(Search::BookVersions::I1::PageElementType.mapping)
    end
  end
end
