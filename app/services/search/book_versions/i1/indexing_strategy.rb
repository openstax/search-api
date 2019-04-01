module Search::BookVersions::I1
  # The indexing strategy is the encapsulation for the index's structure and
  # metadata (including index settings & mappings).
  #
  # The strategy also declares what page element objects it wants indexed.
  class IndexingStrategy
    VERSION = "I1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1

    attr_reader :version

    def initialize
      @version = VERSION
    end

    def index_metadata
      @index_meta ||= begin
        metadata_hashes = [settings, mappings]
        metadata_hashes.inject({}) { |aggregate, hash| aggregate.merge! hash }
      end
    end

    def desired_page_elements
       [
         Openstax::ParagraphElement.new,
         Openstax::FigureElement.new
       ]
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
      { mappings: {} }.merge(PageElementType.mapping)
    end
  end
end
