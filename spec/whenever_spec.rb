require 'rails_helper'

RSpec.describe 'whenever schedule' do

  # Testing rake tasks in the whenever schedule is easy, we just check that
  # they are in the list.  When testing regular ruby calls, we want to run
  # the scheduled runner jobs and see that the appropriate code is reached
  # with the expected arguments.

  let(:rake) { Rake.application }
  let(:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  it 'calls enqueue_index_jobs.rake' do
    expect(scheduled_rake_task("enqueue_index_jobs")).not_to be_nil
  end

  def scheduled_rake_task(name)
    schedule.jobs[:rake].select{|job| job[:task] == name}
  end

end
