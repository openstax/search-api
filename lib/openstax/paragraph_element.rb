module Openstax
  class ParagraphElement
    MATCH_PARAGRAPH = '//p[@id]'
    MATCH_SELECTOR_PARAGRAPH = 'p'

    def matcher
      MATCH_PARAGRAPH
    end

    def create(element, page_position)
      create_paragraph(element, page_position)
    end

    def matches?(element)
      element.matches?(MATCH_SELECTOR_PARAGRAPH)
    end

    private

    def create_paragraph(paragraph_match, page_position)
      visible_content = paragraph_match.text

      IndexableElement.new(type: IndexableElement::ELEMENT_TYPE_PARAGRAPH,
                           page_id: @id,
                           page_position: page_position,
                           visible_content: visible_content)
    end
  end
end
