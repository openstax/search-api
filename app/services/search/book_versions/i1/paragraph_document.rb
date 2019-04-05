module Search::BookVersions::I1
  class ParagraphDocument < PageElementDocument

    def initialize(element:, page_position:, page_id:)
      super(element: element,
            element_type: "paragraph",
            page_position: page_position,
            page_id: page_id)
    end

    def visible_content
      element.text
    end

  end
end
