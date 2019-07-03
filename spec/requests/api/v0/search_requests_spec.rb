require 'rails_helper'
require 'vcr_helper'

RSpec.describe 'api v0 search requests', type: :request, api: :v0, vcr: VCR_OPTS do
  let(:book_version_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:index) { Books::Index.new(book_version_id: book_version_id) }

  before(:each) do
    do_not_record_or_playback do
      if !index.exists?
        index.create
        index.populate
      end
    end
  end

  context "#search" do
    it "searches!" do
      api_get "search?#{query(q: "\"Recall that an atom\"", index_strategy: "i1", search_strategy: "s1")}"
      expect(response).to have_http_status(:ok)

      json = json_response
      expect(json[:overall_took]).not_to be_nil
      expect(json[:hits][:total]).to eq 1
      expect(json[:hits][:hits][0][:_source]).to include(
        page_id: "2c60e072-7665-49b9-a2c9-2736b72b533c@8",
        element_type: "paragraph",
        page_position: 3
      )
      expect(json[:hits][:hits][0][:highlight][:visible_content][0]).to start_with "<em>Recall</em>"
    end

    context "client errors" do
      before { render_rescued_exceptions }

      xit "errors for incompatible strategies" do
        # This test should be filled in once we have a real test case for
        # incompatible indexing and search strategies, so we understand better
        # what the problem would be that we'd want to catch.
      end

      it "422s for unknown search strategy" do
        api_get "search?#{query(q: "Blah", index_strategy: "i1", search_strategy: "booyah")}"
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:messages]).to include(/Unknown search strategy: booyah/)
      end

      it "422's for missing params" do
        api_get "search?q=blah"
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:messages]).to include(/or the value is empty: book/)
      end
    end
  end

  def query(q: nil, index_strategy: nil, search_strategy: nil)
    "q=#{q}&index_strategy=#{index_strategy}&search_strategy=#{search_strategy}&books=14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1"
  end
end
