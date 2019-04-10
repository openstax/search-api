require 'rails_helper'

RSpec.describe Search::BookVersions::I1::PageElementDocument do
  let(:element) do
    instance_double("OpenStax::Cnx::V1::Paragraph")
  end

  subject(:page_element_document) {
    described_class.new(element: element,
                        page_position: 1,
                        element_type: 'page_element',
                        page_id: 1)
  }

  describe "#body" do
    it 'builds a body structure' do
      expect(page_element_document.body).to be_a(Hash)
    end
  end

  describe ".mapping" do
    it 'builds the page_element properties' do
      expect(described_class.mapping).to include(:page_element)
    end
  end
end
