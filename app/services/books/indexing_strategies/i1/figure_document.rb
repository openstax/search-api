module Books::IndexingStrategies::I1
  class FigureDocument < PageElementDocument

    def initialize(element:, page_position:, page_id:)
      super(element: element,
            element_type: self.class.element_type,
            page_position: page_position,
            page_id: page_id)
    end

    def self.element_type
      "figure"
    end

    def visible_content
      element.caption
    end

    def hidden_content
      element.alt_text
    end

  end
end
