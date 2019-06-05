require 'rails_helper'

RSpec.describe Search::BookVersions::I1::PageElementDocument do
  let(:id) { "foo id" }

  let(:element) do
    instance_double("OpenStax::Cnx::V1::Paragraph",
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

  describe "#ok_to_index?" do
    context "there is an id" do
      it 'is ok to index' do
        expect(page_element_document.ok_to_index?).to be_truthy
      end
    end

    context "there is not an id" do
      let(:id) { nil }

      it 'is not ok to index' do
        expect(page_element_document.ok_to_index?).to be_falsey
      end
    end
  end
end
