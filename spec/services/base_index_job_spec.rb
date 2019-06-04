require 'rails_helper'

RSpec.describe BaseIndexJob do
  let(:test) { double("blah") }
  let(:proc) { -> { test.foobar } }

  subject(:base_index_job) {
    described_class.new(book_version_id:        'foo@1',
                        indexing_strategy_name: 'I1',
                        cleanup_after_call:     proc)
  }

  describe '#call and cleanup_when_done' do
    it "calls the when completed hook after a call" do
      allow_any_instance_of(described_class).to receive(:_call)
      expect(test).to receive(:foobar).once

      base_index_job.call
    end
  end

  describe '#remove_associated_book_index_state' do
    let(:book_index_state) { double }
    let(:book_index_find) { double(first: book_index_state) }

    it "removes the associated book index when called" do
      allow(BookIndexState).to receive(:where).and_return(book_index_find)
      expect(book_index_state).to receive(:destroy!).once

      base_index_job.remove_associated_book_index_state
    end
  end
end
