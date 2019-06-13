require "rails_helper"

RSpec.describe ApiV0Helpers, api: :v0 do

  context "#prep_request_args" do
    it "prepends '/api/v0' to the first argument" do
      expect(prep_request_args(['some_path'])[0]).to eq "/api/v0/some_path"
    end

    it "adds default headers if none set" do
      expect(prep_request_args(['blah'])[1][:headers]).to include("CONTENT_TYPE"=>"application/json")
    end

    it "adds headers if some set" do
      headers["foo"] = "bar"
      expect(prep_request_args(['blah'])[1][:headers]).to include("foo" => "bar")
    end

    it "does not override explicitly set headers" do
      headers["foo"] = "bar"
      expect(prep_request_args(['blah', {headers: {"foo" => "keepthis"}}])[1][:headers]).to include(
        "foo" => "keepthis"
      )
    end
  end

end
