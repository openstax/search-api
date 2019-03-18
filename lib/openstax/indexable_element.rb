module Openstax
  class IndexableElement
    ELEMENT_TYPE_PARAGRAPH = "paragraph"
    ELEMENT_TYPE_FIGURE    = "figure"

    attr_reader :type,
                :page_id,
                :title,
                :visible_content,
                :hidden_content,
                :page_position

    def initialize(type:,
                   page_id:,
                   page_position:,
                   title: "",
                   visible_content: "",
                   hidden_content: "")
      @type = type
      @page_id = page_id
      @title = title
      @visible_content = visible_content
      @hidden_content = hidden_content
      @page_position = page_position
    end

    def to_h
      instance_values
    end
  end
end
