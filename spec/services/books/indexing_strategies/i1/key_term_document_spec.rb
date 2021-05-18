require 'rails_helper'

RSpec.describe Books::IndexingStrategies::I1::KeyTermDocument do
  let(:term) { "term" }
  let(:description)  { "test description" }
  let(:element) do
    key_term = instance_double(
      "OpenStax::Cnx::V1::KeyTerm",
      description: description,
      term: term,
      id: 0,
      node: double(xpath: []))
  end

  subject(:key_term_document) {
    described_class.new(element: element, page_position: 1, page_id: 1)
  }

  describe "#title" do
    it 'pulls out the term from the key term' do
      expect(key_term_document.title).to eq term
    end
  end

  describe "#visible_content" do
    it 'pulls out the description from the key term' do
      expect(key_term_document.visible_content).to eq description
    end
  end
end
