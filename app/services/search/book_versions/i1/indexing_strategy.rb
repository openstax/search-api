module Search::BookVersions::I1
  # The indexing strategy is the encapsulation for the index's structure and
  # inspect (including index settings & mappings).
  #
  # The strategy also declares what page element objects it wants indexed.
  class IndexingStrategy
    VERSION = "I1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1

    DESIRED_ELEMENTS_TO_DOCUMENTS = {
      OpenStax::Cnx::V1::Paragraph => ParagraphDocument,
      OpenStax::Cnx::V1::Figure => FigureDocument
    }

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

    def index(book:, index_name:)
      Rails.logger.info("I1::IndexingStrategy: Creating index #{index_name} with #{book.root_book_part.pages.count} pages")
      book.root_book_part.pages.each {|page| index_page(page: page, index_name: index_name) }
    end

    private

    def index_page(page:, index_name:)
      page.elements(element_classes: DESIRED_ELEMENTS_TO_DOCUMENTS.keys).each_with_index do |element, page_position|
        document_class = DESIRED_ELEMENTS_TO_DOCUMENTS[element.class]
        document = document_class.new(element: element,
                                      page_position: page_position,
                                      page_id: page.id)

        if document.ok_to_index?
          OpenSearch::ElasticsearchClient.instance.index(index: index_name,
                                                         type: document.type,
                                                         body: document.body)
        else
          message = "Search::BookVersions::I1::IndexingStrategy: unable to index "/
            "Page id #{element.page_id}, #{element.element_type} due to no element ID"
          Raven.capture_message(message, :extra => element.to_json)
          Rails.logger.warn(message)
        end
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
