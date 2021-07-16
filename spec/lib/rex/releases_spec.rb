require 'rails_helper'
require 'vcr_helper'

require 'rex/releases'

RSpec.describe Rex::Releases, vcr: VCR_OPTS do
  let(:fake_bucket_name) { "spec-bucket-#{SecureRandom.hex(7)}" }

  let(:book1) { { "uid1" => { "defaultVersion" => "1.2"} } }
  let(:book2) { { "uid2" => { "defaultVersion" => "1.1"} } }
  let(:book3) { { "uid3" => { "defaultVersion" => "2.4"} } }
  let(:book_data1) { { books: book1.merge(book2)}.to_json }
  let(:book_data2) { { books: book3}.to_json }
  let(:config_data) { { REACT_APP_ARCHIVE_URL: '/apps/archive/101.42'}.to_json }

  subject(:instance) { described_class.new }

  context 'one release' do
    context 'no config file' do
      it 'reads the release from S3' do
        stub_secrets

        TempAwsEnv.make("one_release_no_config") do |env|
          bucket = env.create_bucket(name: fake_bucket_name, region: 'us-east-1')

          bucket.put_object(key: "rex/releases/foobar/rex/release.json", body: book_data1)

          expect(instance.releases.map(&:id)).to contain_exactly('foobar')
          expect(instance.releases.first.books.count).to eq 2
          expect(instance.releases.map(&:config).uniq).to eq [{}]
        end
      end
    end

    context 'a config file' do
      it 'reads the releases and config from S3' do
        stub_secrets

        TempAwsEnv.make("one_release_yes_config") do |env|
          bucket = env.create_bucket(name: fake_bucket_name, region: 'us-east-1')

          bucket.put_object(key: "rex/releases/foobar/rex/release.json", body: book_data1)
          bucket.put_object(key: "rex/releases/foobar/rex/config.json", body: config_data)

          expect(instance.releases.map(&:id)).to contain_exactly('foobar')
          expect(instance.releases.first.books.count).to eq 2
          expect(instance.releases.map(&:config).uniq).to match [JSON.parse(config_data)]
        end
      end
    end
  end

  context 'multiple releases' do
    it 'reads the releases from S3' do
      stub_secrets

      TempAwsEnv.make("multiple_releases") do |env|
        bucket = env.create_bucket(name: fake_bucket_name, region: 'us-east-1')

        bucket.put_object(key: "rex/releases/alpha/1/rex/release.json", body: book_data1)
        bucket.put_object(key: "rex/releases/beta/foo/2/bar/3/rex/release.json", body: book_data2)

        expect(instance.releases.map(&:id)).to contain_exactly('alpha/1', 'beta/foo/2/bar/3')
        expect(instance.releases.first.books.count).to eq 2
        expect(instance.releases.second.books.count).to eq 1
      end
    end
  end

  context 'not a release' do
    context 'file name not release.json' do
      it 'finds no release' do
        stub_secrets

        TempAwsEnv.make("not_a_release") do |env|
          bucket = env.create_bucket(name: fake_bucket_name, region: "us-east-1")
          bucket.put_object(key: "rex/releases/alpha/1/rex/giraffe.json", body: book_data1)

          expect(instance.releases.count).to eq 0
        end
      end
    end

    context 'no rex parent folder for the release json' do
      it 'finds no release' do
        stub_secrets

        TempAwsEnv.make("finds_no_release") do |env|
          bucket = env.create_bucket(name: fake_bucket_name, region: "us-east-1")
          bucket.put_object(key: "rex/releases/alpha/1/release.json", body: book_data1)

          expect(instance.releases.count).to eq 0
        end
      end
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
