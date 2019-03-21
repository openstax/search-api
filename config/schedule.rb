require_relative "application" unless defined? Rails # to test node type

if ::Rails.application.is_manager_node?
  every 5.minutes do
    rake 'enqueue_index_jobs'
  end
end
