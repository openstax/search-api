require 'rails_helper'
require 'vcr_helper'

RSpec.describe Books::SearchStrategies::S1::Strategy , type: :request, api: :v0, vcr: VCR_OPTS do
  let(:book_version_id1) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:book_version_id2) { '8d50a0af-948b-4204-a71d-4826cba765b8@15.3' }
  let(:index1) { Books::Index.new(book_version_id: book_version_id1) }
  let(:index2) { Books::Index.new(book_version_id: book_version_id2) }
  let(:index_name1) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1_i1' }
  let(:index_name2) { '8d50a0af-948b-4204-a71d-4826cba765b8@15.3_i1' }

  subject(:search_strategy) { Books::SearchStrategies::S1::Strategy.new(index_names: index_names) }

  context 'one index' do
    let(:index_names) { [index_name1] }
    let(:search_term) { 'cytokinesis' }

    before(:each) do
      do_not_record_or_playback do
        if !index1.exists?
          index1.create
          index1.populate
        end
      end
    end

    it "finds the search term" do
      result = search_strategy.search(query_string: search_term)
      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first).to include(search_term)
    end
  end
end
