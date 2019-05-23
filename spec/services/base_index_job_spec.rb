require 'rails_helper'

RSpec.describe BaseIndexJob do
  let(:test) { double("blah") }
  let(:proc) { -> { test.foobar } }

  subject(:base_index_job) {
    described_class.new(book_version_id:        'foo@1',
                        indexing_strategy_name: 'I1',
                        cleanup_after_call:     proc)
  }

  describe '#cleanup_after_call' do
    it "calls the when completed hook" do
      expect(test).to receive(:foobar).once

      base_index_job.cleanup_after_call
    end
  end
end
