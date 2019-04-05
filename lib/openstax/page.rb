module Openstax
  # A Openstax::Page is the object that "represents" a page in a book.
  #
  # An desired-page-elements is injected in order to determine what sub-page
  # elements a page should be concerned about.
  class Page
    def initialize(id:, data:)
      @id = id
      @data = data
    end

    def elements(element_classes)
      # This join is important to OR together all the xpaths in order to determine
      # the matched element's order inside the page. Xpath does this for us.
      match_all_elements = element_classes.map(&:matcher).join(' | ')

      working_element_index = []

      # Match on all the elements. Create Element objects with the matching xpath node.
      content_dom.xpath(match_all_elements).each_with_index do | xpath_element |
        element_class = element_classes.detect do | elem_class |
          elem_class.matches?(xpath_element)
        end

        element = element_class.new(node: xpath_element)
        working_element_index << element if element
      end

      working_element_index
    end

    def content_dom
      @content_dom ||= Nokogiri::HTML(@data["content"])
    end
  end
end
