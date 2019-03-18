module Openstax
  class Page
    MATCH_PARAGRAPH = '//p[@id]'
    MATCH_FIGURE = '//figure'
    MATCH_SELECTOR_PARAGRAPH = 'p'
    MATCH_SELECTOR_FIGURE = 'figure'
    MATCH_FIGURE_VISIBLE_TEXT = './/figcaption'
    MATCH_FIGURE_HIDDEN_TEXT = './/*[@data-alt]'

    MATCH_ALL_ELEMENTS = [
      MATCH_PARAGRAPH,
      MATCH_FIGURE
    ].join(' | ')

    attr_reader :indexable_elements

    def initialize(id:, data:)
      @id = id
      @data = data
      @indexable_elements = []
    end

    def process_for_indexable_objects
      content_dom.xpath(MATCH_ALL_ELEMENTS).each_with_index do | xpath_element, index |
        indexable_element = create_element(xpath_element, index+1)
        @indexable_elements << indexable_element if indexable_element
      end
    end

    private

    def create_element(ordered_element, page_position)
      if ordered_element.matches?(MATCH_SELECTOR_PARAGRAPH)
        return create_paragraph(ordered_element, page_position)
      end

      if ordered_element.matches?(MATCH_SELECTOR_FIGURE)
        return create_figure(ordered_element, page_position)
      end
    end

    def create_paragraph(paragraph_match, page_position)
      visible_content = paragraph_match.text

      IndexableElement.new(type: IndexableElement::ELEMENT_TYPE_PARAGRAPH,
                           page_id: @id,
                           page_position: page_position,
                           visible_content: visible_content)
    end

    def create_figure(figure_match, page_position)
      visible_content = figure_match.xpath('.//figcaption').first.try(:text)
      hidden_content = figure_match.xpath('.//*[@data-alt]').first.try(:text)

      IndexableElement.new(type: IndexableElement::ELEMENT_TYPE_FIGURE,
                           page_id: @id,
                           page_position: page_position,
                           visible_content: visible_content,
                           hidden_content: hidden_content)
    end

    def content_dom
      @content_dom ||= Nokogiri::HTML(@data["content"])
    end
  end
end
