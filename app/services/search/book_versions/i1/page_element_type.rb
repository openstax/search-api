module Search::BookVersions::I1

  # A PageElementType is the index document structure.  Each row in the index
  # is of this type.
  #
  # Note: ElasticSearch is standardizing to the use of one type per index.
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
        }
      }
    end
  end
end
