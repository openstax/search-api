require 'rails_helper'
require 'rex/release'

RSpec.describe Rex::Release do
  describe '#pipeline_version' do
    context 'when there is no config data' do
      it 'gives "legacy" as the pipeline version' do
        instance = described_class.new(id: 'foo', data: {}, config: {})
        expect(instance.pipeline_version).to eq 'legacy'
      end
    end

    context 'when there is config data' do
      it 'gives a real pipeline version' do
        instance = described_class.new(id: 'foo', data: {}, config: { 'REACT_APP_ARCHIVE_URL' => '/apps/archive/101.42'})
        expect(instance.pipeline_version).to eq '101.42'
      end
    end
  end
end
