module Books::IndexingStrategies::I1
  # The indexing strategy is the encapsulation for the index's structure and
  # inspect (including index settings & mappings).
  #
  # The strategy also declares what page element objects it wants indexed.
  class Strategy
    SHORT_NAME = "i1"
    NUM_SHARDS = 1
    NUM_REPLICAS = 1

    DESIRED_ELEMENTS_TO_DOCUMENTS = {
      OpenStax::Cnx::V1::Paragraph => ParagraphDocument,
      OpenStax::Cnx::V1::Figure => FigureDocument
    }

    delegate :short_name, to: :class

    def self.short_name
      SHORT_NAME
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

    def total_number_of_elements_to_index(book:)
      book.root_book_part.pages.map{|page| page.elements(element_classes: DESIRED_ELEMENTS_TO_DOCUMENTS.keys).count }.sum
    end

    private

    def index_page(page:, index_name:)
      page.elements(element_classes: DESIRED_ELEMENTS_TO_DOCUMENTS.keys).each_with_index do |element, page_position|
        begin
          document_class = DESIRED_ELEMENTS_TO_DOCUMENTS[element.class]
          document = document_class.new(element: element,
                                        page_position: page_position,
                                        page_id: page.id)

          OsElasticsearchClient.instance.index(index: index_name,
                                               type:  document.type,
                                               body:  document.body)
        rescue ElementIdMissing => ex
          Raven.capture_message(ex.message, :extra => element.to_json)
          Rails.logger.error(ex)
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
