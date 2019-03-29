require 'rails_helper'
require 'vcr_helper'

require 'rex_releases'

RSpec.describe ElasticsearchClient, vcr: VCR_OPTS do

  before {
    # Even in VCR playback, the code freaks out if these aren't set (in
    # playback, values don't matter)
    ENV['AWS_ACCESS_KEY_ID'] ||= 'foo'
    ENV['AWS_SECRET_ACCESS_KEY'] ||= 'bar'
  }

  let(:fake_es_domain_name) { "spec-esdomain-#{SecureRandom.hex(7)}" }

  it 'can access a restricted AWS ES domain using signed requests' do
    TempAwsEnv.make do |env|
      domain_status = env.create_elasticsearch_domain(name: fake_es_domain_name)

      signing_client = ElasticsearchClient.new(
        url: "https://#{domain_status.endpoint}",
        sign_aws_requests: true
      )

      resp = signing_client.search q: "test"
      expect(resp).to have_key("took")

      non_signing_client = ElasticsearchClient.new(
        url: "https://#{domain_status.endpoint}",
        sign_aws_requests: false
      )

      expect {
        non_signing_client.search q: "test"
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::Forbidden)
    end
  end

end
