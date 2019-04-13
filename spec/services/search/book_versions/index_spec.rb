require 'rails_helper'
require 'vcr_helper'

# In this test, the book content is drawn from the file fixture (to limit the
# book to 1 page) & the page content is drawn from cnx archive and recorded thru
# vcr
#
# ElasticSearch must be running for this test to succeed
# e.g  docker run
#          -p 9200:9200 -p 9300:9300
#          -v elasticsearch:/usr/share/elasticsearch/data
#          -e "discovery.type=single-node"
#          docker.elastic.co/elasticsearch/elasticsearch:6.3.2
RSpec.describe Search::BookVersions::Index, vcr: VCR_OPTS do
  let(:cnx_book_id) { '14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22' }
  let(:book_version) { "15.1" }
  let(:test_book_json) { JSON.parse(file_fixture('mini.json').read) }

  subject(:index) { described_class.new(book_guid: cnx_book_id, book_version: book_version) }

  def delete_index
    if OpenSearch::ElasticsearchClient.instance.indices.exists? index: index.name
      OpenSearch::ElasticsearchClient.instance.indices.delete index: index.name
    end
  end

  before { delete_index }
  after { delete_index }

  describe "#create" do
    it 'creates the index' do
      index.create
      expect(OpenSearch::ElasticsearchClient.instance.indices.exists?(index: index.name)).to be_truthy
    end
  end

  describe "#populate" do
    let(:test_book_url) {
      "https://archive.cnx.org/contents/#{cnx_book_id}@#{book_version}"
    }
    let(:test_page_url) {
      "#{test_book_url}:ada35081-9ec4-4eb8-98b2-3ce350d5427f@6"
    }

    before do
      allow(OpenStax::Cnx::V1).to receive(:fetch).with(test_book_url).and_return(test_book_json)
      allow(OpenStax::Cnx::V1).to receive(:fetch).with(test_page_url).and_call_original
    end

    it 'populates the index' do
      index.create
      index.populate
      sleep 1 if VCR.current_cassette.try!(:recording?)  # wait for ES to finish

      expect(OpenSearch::ElasticsearchClient.instance.count(index: index.name)["count"]).to eq 8
    end
  end

  describe "#delete" do
    it 'deletes the index' do
      index.create
      expect(OpenSearch::ElasticsearchClient.instance.indices.exists?(index: index.name)).to be_truthy
      index.delete
      expect(OpenSearch::ElasticsearchClient.instance.indices.exists?(index: index.name)).to be_falsey
    end
  end

  describe "#name" do
    it 'derives the index name' do
      expect(index.name).to eq "14fb4ad7-39a1-4eee-ab6e-3ef2482e3e22@15.1_i1"
    end
  end
end
