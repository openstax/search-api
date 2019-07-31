require 'rails_helper'

RSpec.describe Books::IndexingStrategies::I1::PageElementDocument do
  let(:id) { "foo id" }

  let(:element) do
    instance_double("OpenStax::Cnx::V1::Paragraph",
                    node: double(xpath: []),
                    id: id)
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

  describe "#initialize" do
    context "a valid object" do
      it 'will create a valid object' do
        expect(page_element_document).to be_a_kind_of(Books::IndexingStrategies::I1::PageElementDocument)
      end
    end

    context "element ID is nil" do
      let(:id) { nil }

      it 'raises an exception of the element id is missing' do
        expect { page_element_document }.to raise_error(Books::IndexingStrategies::I1::ElementIdMissing)
      end
    end
  end
end
