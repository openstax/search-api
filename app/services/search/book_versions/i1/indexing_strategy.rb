module Search::BookVersions::I1
  # The indexing strategy is the encapsulation for the index's structure and
  # metadata (including index settings & mappings).
  #
  # The strategy also declares what page element objects it wants indexed.
  class IndexingStrategy
    VERSION = "I1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1

    DESIRED_ELEMENTS_TO_DOCUMENTS = [
      OpenStax::ParagraphElement => ParagraphDocument,
      OpenStax::FigureElement => FigureDocument
    ]

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

    def index(book:)
      book.parts.each{ |part| index_part(part: part) }
    end

    private

    # See lib/openstax/book.rb for a description of "parts"
    def index_part(part:)
      if part.is_chapter?
        # Don't care about chapters in this strategy, so recur
        part.pages.each{ |page| index_page(page: page) }
      else
        # Don't care about units in this strategy, so recur
        part.parts.each{ |part| index_part(part: part) }
      end
    end

    def index_page(page:)
      page.elements(DESIRED_ELEMENTS_TO_DOCUMENTS.keys).each_with_index do |element, page_position|
        document_class = DESIRED_ELEMENTS_TO_DOCUMENTS[element.class]
        document = document_class.new(element: element,
                                      page_position: page_position,
                                      page_id: page.id)

        ElasticsearchClient.instance.index(index: name,
                                           type: document.type,
                                           body: document.body)
      end
    end

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
      { mappings: {} }.merge(PageElementDocument.mapping)
    end
  end
end
