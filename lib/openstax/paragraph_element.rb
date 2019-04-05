module Openstax
  class ParagraphElement

    MATCH_PARAGRAPH = '//p[@id]'
    MATCH_SELECTOR_PARAGRAPH = 'p'

    def initialize(node:)
      super(node)
    end

    def text
      node.text
    end

    def self.matcher
      MATCH_PARAGRAPH
    end

    def self.matches?(node)
      node.matches?(MATCH_SELECTOR_PARAGRAPH)
    end

  end
end
