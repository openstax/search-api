require 'rails_helper'

RSpec.describe Rex::Config do
  describe '#pipeline_version' do
    context 'when there is no config data' do
      it 'gives nil as the pipeline version' do
        instance = described_class.new(data: {})
        expect(instance.pipeline_version).to be_nil
      end
    end

    context 'when there is config data' do
      it 'gives a real pipeline version' do
        instance = described_class.new(data: { 'REACT_APP_ARCHIVE_URL' => '/apps/archive/101.42'})
        expect(instance.pipeline_version).to eq '101.42'
      end
    end
  end
end
