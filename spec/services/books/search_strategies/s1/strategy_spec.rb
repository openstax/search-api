require 'rails_helper'
require 'vcr_helper'

RSpec.describe Books::SearchStrategies::S1::Strategy , type: :request, api: :v0, vcr: VCR_OPTS do
  let(:book_version_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
  let(:index) { Books::Index.new(book_version_id: book_version_id) }
  let(:index_name) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1_i1' }

  subject(:search_strategy) { Books::SearchStrategies::S1::Strategy.new(index_names: index_names) }

  context 'one index' do
    let(:index_names) { [index_name] }
    let(:search_term) { 'cytokinesis' }

    before do
      do_not_record_or_playback do
        if !index.exists?
          index.create
          index.populate
        end
      end
    end

    it "finds the search term" do
      result = search_strategy.search(query_string: search_term)
      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first).to include(search_term)
    end

    it "doesnt find a hit in the preface page" do
      # Welcome only in preface page
      result = search_strategy.search(query_string: "Welcome")
      expect(result["hits"]["hits"]).to be_empty
    end

    it "has empty hits for a term not found" do
      result = search_strategy.search(query_string: 'defnotthereforsure')
      expect(result["hits"]["hits"]).to be_empty
    end
  end

  context 'multiple indexes' do
    let(:book_version_id2) { '8d50a0af-948b-4204-a71d-4826cba765b8@15.3' }
    let(:index2) { Books::Index.new(book_version_id: book_version_id2) }
    let(:index_name2) { '8d50a0af-948b-4204-a71d-4826cba765b8@15.3_i1' }

    let(:index_names) { [index_name, index_name2] }
    let(:search_term) { 'organism' }

    before do
      do_not_record_or_playback do
        if !index.exists?
          index.create
          index.populate
        end
        if !index2.exists?
          index2.create
          index2.populate
        end
      end
    end

    it "finds the search term" do
      result = search_strategy.search(query_string: search_term)

      expect((result["hits"]["hits"].select{|hit| hit['_index'].include?('14fb4ad7')}).present?).to be_truthy
      expect((result["hits"]["hits"].select{|hit| hit['_index'].include?('8d50a0af')}).present?).to be_truthy
    end
  end

  context 'when search content has embedded mathml' do
    let(:cnx_book_id) { '54fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1' }
    let(:math_book_json) { JSON.parse(file_fixture('mini_math_book.json').read) }
    let(:math_page_json) { JSON.parse(file_fixture('mini_math_page.json').read) }
    let(:math_book_url) { "https://archive.cnx.org/contents/#{cnx_book_id}"}
    let(:math_page_url) { "#{math_book_url}:ada35081-9ec4-4eb8-98b2-3ce350d5427f@6"}
    let(:index) { Books::Index.new(book_version_id: cnx_book_id) }
    let(:index_names) { ['54fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1_i1'] }

    let(:paragraph_search_term) { 'Einstein' }
    let(:figure_search_term) { 'Malony' }
    let(:search_term_embedded_in_mathml) { 'Harlow' }

    before do
      allow(OpenStax::Cnx::V1).to receive(:fetch).with(math_book_url).and_return(math_book_json)
      allow(OpenStax::Cnx::V1).to receive(:fetch).with(math_page_url).and_return(math_page_json)

      do_not_record_or_playback do
        if !index.exists?
          index.create
          index.populate
          sleep(2)
        end
      end
    end

    it 'finds the search term in a paragraph excluding the mathml' do
      result = search_strategy.search(query_string: paragraph_search_term)

      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first.include?(paragraph_search_term)).to be_truthy
      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first.include?(Books::IndexingStrategies::I1::PageElementDocument::MATHML_REPLACEMENT)).to be_truthy
    end

    it 'doesnt find a search term embedded in the mathml' do
      result = search_strategy.search(query_string: search_term_embedded_in_mathml)
      expect(result["hits"]["hits"].count).to eq 0
    end

    it 'finds the search term in a figure excluding the mathml' do
      result = search_strategy.search(query_string: figure_search_term)

      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first.include?(figure_search_term)).to be_truthy
      expect(result["hits"]["hits"].first["highlight"]["visible_content"].first.include?(Books::IndexingStrategies::I1::PageElementDocument::MATHML_REPLACEMENT)).to be_truthy
    end
  end
end
