require 'rails_helper'
require 'vcr_helper'

require 'openstax/rex_releases'

RSpec.describe Openstax::RexReleases, vcr: VCR_OPTS do

  let(:fake_bucket_name) { "spec-bucket-#{SecureRandom.hex(7)}" }

  it 'reads the release IDs from S3' do
    stub_secrets

    TempAwsEnv.make do |env|
      bucket = env.create_bucket(name: fake_bucket_name, region: "us-east-1")

      bucket.put_object(key: "rex/releases/alpha/rex/release.json", body: {whatever: 'here'}.to_json)
      bucket.put_object(key: "rex/releases/beta/rex/release.json", body: {whatever: 'here'}.to_json)

      instance = described_class.new

      expect(instance.releases.map(&:id)).to contain_exactly("alpha", "beta")
    end
  end

  def stub_secrets
    allow(Rails.application).to receive(:secrets).and_return(OpenStruct.new(
      rex_release_bucket: {
        name: fake_bucket_name,
        region: "us-east-1"
      }
    ))
  end

end
