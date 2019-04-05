module Search::BookVersions::I1

  # A PageElementDocument is the index document structure.
  #
  # Note: ElasticSearch is standardizing to the use of one type per index.
  class PageElementDocument

    attr_reader :element, :element_type, :page_position, :page_id

    def initialize(element:, element_type:, page_position:, page_id:)
      @element = element
      @element_type = element_type
      @page_position = page_position
      @page_id = page_id
    end

    def type
      "page_element"
    end

    def body
      {
        element_type: element_type,
        page_id: page_id,
        page_position: page_position,
        title: title,
        visible_content: visible_content,
        hidden_content: hidden_content
      }
    end

    def self.mapping
      {
        page_element: {
          properties: {
            element_type: { type: 'text' },
            page_id: { type: 'text' },
            page_position: { type: 'integer' },
            title: { type: 'text' },
            visible_content: { type: 'text' },
            hidden_content: { type: 'text' }
          }
        }
      }
    end

    # Override these methods in specific element subclasses if appropriate
    def title;           nil; end # TODO nil or ""?
    def visible_content; nil; end
    def hidden_content;  nil; end

  end
end
