require 'rails_helper'

RSpec.describe Search::BookVersions::I1::FigureDocument do
  let(:caption)  { "test caption" }
  let(:alt_text) { "alt text" }
  let(:element) do
    figure = instance_double(
      "OpenStax::Cnx::V1::Figure",
      caption: caption,
               alt_text: alt_text)
  end

  subject(:figure_document) {
    described_class.new(element: element, page_position: 1, page_id: 1)
  }

  describe "#visible_content" do
    it 'pulls out the caption from the figure' do
      expect(figure_document.visible_content).to eq caption
    end
  end

  describe "#hidden_content" do
    it 'pulls out the alt-text from the figure' do
      expect(figure_document.hidden_content).to eq alt_text
    end
  end
end
