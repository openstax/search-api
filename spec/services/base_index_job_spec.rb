require 'rails_helper'

RSpec.describe BaseIndexJob do
  class Test
    def self.foobar
    end
  end

  let(:proc) {
    -> {
      Test.foobar
    }
  }

  subject(:base_index_job) {
    described_class.new(book_version_id: 'foo@1',
                        indexing_version: 'I1',
                        when_completed_proc: proc)
  }

  describe '#when_completed' do
    it "calls the when completed hook" do
      expect(Test).to receive(:foobar).once

      base_index_job.when_completed
    end
  end
end
