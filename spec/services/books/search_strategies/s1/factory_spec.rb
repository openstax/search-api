require 'rails_helper'

RSpec.describe Books::SearchStrategies::S1::Factory do
  let(:book_version_ids) { ['foo@1.1'] }

  subject(:factory) {
    described_class.build(book_version_ids: book_version_ids,
                          index_strategy: index_strategy,
                          search_strategy: search_strategy)
  }

  describe ".build" do
    let(:index_strategy) { 'i1' }
    let(:search_strategy) { 's1' }

    it 'pulls out the caption from the figure' do
      expect(factory).to be_kind_of(Books::SearchStrategies::S1::Strategy)
    end

    context 'unknown strategy' do
      let(:search_strategy) { 's_foo' }

      it 'pulls out the caption from the figure' do
        expect { factory }.to raise_error(Books::SearchStrategies::S1::UnknownSearchStrategy)
      end
    end

    context 'incompatible strategy' do
      let(:index_strategy) { 'i_foo' }

      it 'pulls out the caption from the figure' do
        expect { factory }.to raise_error(Books::SearchStrategies::S1::IncompatibleStrategies)
      end
    end
  end
end
