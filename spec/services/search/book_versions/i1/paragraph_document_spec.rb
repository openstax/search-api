require 'rails_helper'

RSpec.describe Search::BookVersions::I1::ParagraphDocument do
  let(:text) { "foo text" }

  let(:element) do
    figure = instance_double(
      "OpenStax::Cnx::V1::Paragraph",
      id: 0,
      text: text)
  end

  subject(:paragraph_document) {
    described_class.new(element: element, page_position: 1, page_id: 1)
  }

  describe "#visible_content" do
    it 'pulls out the caption from the paragraph' do
      expect(paragraph_document.visible_content).to eq text
    end
  end
end
