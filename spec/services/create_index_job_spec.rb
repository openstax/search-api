require 'rails_helper'

RSpec.describe CreateIndexJob do
  let(:body) {
    {
      type: "CreateIndexJob",
      book_version_id: "foo@1",
      indexing_strategy_name: "I1",
      status: { status: "successful" },
      es_stats: { num_docs_in_index: 7000 },
      time_took: '00:05:00'
    }
  }

  subject(:create_index_job) { described_class.build_object(params: body, cleanup_after_call: nil) }

  describe '#_call' do
    it "recreates the index" do
      expect_any_instance_of(Books::Index).to receive(:recreate).once

      create_index_job.send(:_call)
    end
  end

  describe '#cleanup_when_done' do
    let(:book_index_state) { double }

    it "marks the book index state as created" do
      allow(create_index_job).to receive(:find_associated_book_index_state).and_return(book_index_state)

      expect(book_index_state).to receive(:mark_created).once
      create_index_job.cleanup_when_done
    end
  end

  describe '#as_json' do
    it 'converts to json' do
      expect(create_index_job.to_json).to include_json(
                                            type: 'CreateIndexJob',
                                            book_version_id: 'foo@1',
                                            indexing_strategy_name: "I1")
    end
  end
end
