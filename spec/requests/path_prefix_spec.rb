require 'rails_helper'

RSpec.describe 'path prefixes with "open-search" work', type: :request do

  it "should route requests that have the prefix" do
    expect_any_instance_of(Api::V0::SearchController).to receive(:search)
    get("/open-search/api/v0/search")
  end

  it "should route requests that don't have the prefix" do
    expect_any_instance_of(Api::V0::SearchController).to receive(:search)
    get("/api/v0/search")
  end

end
