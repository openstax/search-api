module Books::IndexingStrategies::I1
  class BookDocs
    DESIRED_ELEMENTS_TO_DOCUMENTS = {
      OpenStax::Cnx::V1::Paragraph => ParagraphDocument,
      OpenStax::Cnx::V1::Figure => FigureDocument
    }

    def initialize(book:)
      @book = book
    end

    def docs
      @docs ||= begin
        @book.root_book_part.pages.each_with_object([]) do |page, accum|
          next if page.preface? || page.index?

          page.
            elements(element_classes: DESIRED_ELEMENTS_TO_DOCUMENTS.keys).
            each_with_index { |element, page_position|
              doc = create_document(element, page_position, page.id)
              accum << doc
            }
        end
      end
    end

    private

    def create_document(element, page_position, page_id)
      doc_class = DESIRED_ELEMENTS_TO_DOCUMENTS[element.class]
      doc_class.new(element: element,
                    page_position: page_position,
                    page_id: page_id)
    end
  end
end
