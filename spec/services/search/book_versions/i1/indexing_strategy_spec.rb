require 'rails_helper'
require 'vcr_helper'

RSpec.describe Search::BookVersions::I1::IndexingStrategy do
  let(:element) do
    Openstax::IndexableElement.new(
      type: Openstax::IndexableElement::ELEMENT_TYPE_PARAGRAPH,
      page_id: 1,
      title: 'foo title',
      visible_content: 'A cow jumped over the mooon',
      hidden_content: nil,
      page_position: 1)
  end

  describe "#index_metadata" do
    subject(:index_metadata ) { described_class.new.index_metadata }

    it 'creates index metadata' do
      expect(index_metadata.dig(:page_element, :properties, :title, :type)).to eq 'text'
      expect(index_metadata.dig(:page_element, :properties, :visible_content, :type)).to eq 'text'
      expect(index_metadata.dig(:settings, :analysis, :analyzer)).to eq :simple
      expect(index_metadata.dig(:settings, :index, :number_of_replicas)).to eq 1
      expect(index_metadata.dig(:mappings)).to eq({})
    end
  end

  describe "#index_row" do
    subject(:strategy ) { described_class.new }
    let(:index_name) { 'test' }

    it 'creates the row successfully in elastic search' do
      allow(ElasticsearchClient.instance).to receive(:index)
      strategy.index_document(element: element, index_name: index_name)
      expect(ElasticsearchClient.instance).to have_received(:index)
    end
  end

  describe "#desired_page_elements" do
    subject(:desired_page_elements ) { described_class.new.desired_page_elements }

    it 'returns page elements for the strategy' do
      expect(desired_page_elements[0]).to be_an_instance_of(Openstax::ParagraphElement)
      expect(desired_page_elements[1]).to be_an_instance_of(Openstax::FigureElement)
    end
  end
end
