module Openstax
  # A Openstax::Page is the object that "represents" a page in a book.
  #
  # An desired-page-elements is injected in order to determine what sub-page
  # elements a page should be concerned about.
  class Page
    def initialize(id:, data:, desired_page_elements:)
      @id = id
      @data = data
      @desired_page_elements = desired_page_elements
      @indexable_elements
    end

    def indexable_elements
      @indexable_elements ||= process_for_indexable_objects
    end

    private

    def process_for_indexable_objects
      # This join is important to OR together all the xpaths in order to determine
      # the matched element's order inside the page. Xpath does this for us.
      match_all_elements = @desired_page_elements.map(&:matcher).join(' | ')

      working_element_index = []

      # Match on all the elements. With a match, call create on it w/ the xpath node
      # to create an indexable element.
      #
      # The indexable element is later iterated to send to ElasticSearch.
      content_dom.xpath(match_all_elements).each_with_index do | xpath_element, order_in_page |
        indexable_page_element = @desired_page_elements.detect do | elem |
          elem.matches?(xpath_element)
        end

        indexable_element = indexable_page_element.create(xpath_element, order_in_page+1)
        working_element_index << indexable_element if indexable_element
      end

      working_element_index
    end

    def content_dom
      @content_dom ||= Nokogiri::HTML(@data["content"])
    end
  end
end
