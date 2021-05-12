module Books::IndexingStrategies::I1
  class KeyTermDocument < PageElementDocument
    def initialize(element:, page_position:, page_id:)
      super(element: element,
            element_type: self.class.element_type,
            page_position: page_position,
            page_id: page_id)
    end

    def self.element_type
      "key_term"
    end

    def visible_content
      [element.term, element.description]
    end
  end
end
