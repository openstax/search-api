module Openstax
  class FigureElement < Element

    MATCH_FIGURE = '//figure'
    MATCH_SELECTOR_FIGURE = 'figure'
    MATCH_FIGURE_CAPTION = './/figcaption'
    MATCH_FIGURE_ALT_TEXT = './/*[@data-alt]'

    def initialize(node:)
      super(node)
    end

    def caption
      node.xpath(MATCH_FIGURE_CAPTION).first.try(:text)
    end

    def alt_text
      node.xpath(MATCH_FIGURE_ALT_TEXT).first.try(:text)
    end

    def self.matcher
      MATCH_FIGURE
    end

    def self.matches?(node)
      node.matches?(MATCH_SELECTOR_FIGURE)
    end

  end
end
