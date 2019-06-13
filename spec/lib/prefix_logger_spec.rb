require 'rails_helper'

RSpec.describe "Prefix Logger" do

  let(:klass) {
    Class.new do
      prefix_logger "Hiya"

      def do_it_with_args
        log_info "there"
      end

      def do_it_with_block
        log_info { "there" }
      end
    end
  }

  it "logs with a prefix using args" do
    expect(Rails.logger).to receive(:info).with "Hiya: there"
    expect(klass.new.do_it_with_args)
  end

  it "logs with a prefix using block message" do
    expect(Rails.logger).to receive(:info).with "Hiya: there"
    expect(klass.new.do_it_with_block)
  end

end
