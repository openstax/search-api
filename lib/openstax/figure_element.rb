module Openstax
  class FigureElement
    MATCH_FIGURE = '//figure'
    MATCH_SELECTOR_FIGURE = 'figure'
    MATCH_FIGURE_VISIBLE_TEXT = './/figcaption'
    MATCH_FIGURE_HIDDEN_TEXT = './/*[@data-alt]'

    def matcher
      MATCH_FIGURE
    end

    def create(element, page_position)
      create_figure(element, page_position)
    end

    def matches?(element)
      element.matches?(MATCH_SELECTOR_FIGURE)
    end

    private

    def create_figure(figure_match, page_position)
      visible_content = figure_match.xpath(MATCH_FIGURE_VISIBLE_TEXT).first.try(:text)
      hidden_content = figure_match.xpath(MATCH_FIGURE_HIDDEN_TEXT).first.try(:text)

      IndexableElement.new(type: IndexableElement::ELEMENT_TYPE_FIGURE,
                           page_id: @id,
                           page_position: page_position,
                           visible_content: visible_content,
                           hidden_content: hidden_content)
    end
  end
end
