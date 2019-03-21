require 'rails_helper'

RSpec.describe 'enqueue_index_jobs', type: :rake do
  include_context 'rake'

  it "works as a placeholder" do
    expect(Rails.logger).to receive(:info) do |&block|
      expect(block.call).to match /Ran placeholder/
    end
    call
  end

end
