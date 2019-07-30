module Books::IndexingStrategies::I1
  class ElementIdMissing < StandardError
    def initialize(element_type:, page_id:)
      super("page_id #{page_id} missing element id for element #{element_type}")
    end
  end

  # A PageElementDocument is the index document structure.
  #
  # Note: ElasticSearch is standardizing to the use of one type per index.
  class PageElementDocument
    attr_reader :element, :element_type, :element_id, :page_position, :page_id

    MATHML_REPLACEMENT = "#{"\u2026"}"

    def self.mapping
      {
        page_element: {
          properties: {
            element_type: { type: 'text' },
            element_id: { type: 'text' },
            page_id: { type: 'text' },
            page_position: { type: 'integer' },
            title: { type: 'text' },
            visible_content: { type: 'text' },
            hidden_content: { type: 'text' }
          }
        }
      }
    end

    def initialize(element:, element_type:, page_position:, page_id:)
      @element = element
      @element_type = element_type
      @page_position = page_position
      @page_id = page_id

      if element.id.nil?
        raise ElementIdMissing.new(element_type: element_type, page_id: page_id)
      end
      @element_id = element.id

      replace_mathml_nodes
    end

    def type
      "page_element"
    end

    def body
      {
        element_type: element_type,
        element_id: element_id,
        page_id: page_id,
        page_position: page_position,
        title: title,
        visible_content: visible_content,
        hidden_content: hidden_content
      }
    end

    def replace_mathml_nodes
      element.node.xpath(".//math").each do |div|
        div.replace("<span>#{MATHML_REPLACEMENT}</span>")
      end
    end

    # Override these methods in specific element subclasses if appropriate
    def title;           nil; end # TODO nil or ""?
    def visible_content; nil; end
    def hidden_content;  nil; end
  end
end
