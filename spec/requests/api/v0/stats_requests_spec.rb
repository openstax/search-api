require 'rails_helper'

RSpec.describe 'api v0 stats requests', type: :request, api: :v0 do
  let(:stats) {
    {
      es_version: "6.7.2",
      book_indexes: [
        {
          id: "8d50a0af-948b-4204-a71d-4826cba765b8@15.3_i1",
          num_docs: "7166",
          state: "create pending"
        },
        {
          id: "031da8d3-b525-429c-80cf-6c8ed997733a@14.4_i1",
          num_docs: "12349", state: "created"
        }
      ]
    }
  }

  before do
    allow_any_instance_of(Stats).to receive(:call).and_return(stats)
  end

  context "#stats" do
    it "returns stats" do
      api_get 'stats'
      expect(response).to have_http_status(:ok)

      json = json_response
      expect(json[:es_version]).to eq "6.7.2"
      expect(json[:book_indexes].count).to eq 2
    end
  end
end
