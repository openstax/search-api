module Search::BookVersions::I1
  class PageElementType
    def self.index_type
      "page_element"
    end

    def self.mapping
      {
        page_element: {
          properties: {
            element_type: { type: 'text' },
            title: { type: 'text' },
            visible_content: { type: 'text' },
            hidden_content: { type: 'text' },
            page_position: { type: 'integer' }
          }
        }}
    end
  end
end
