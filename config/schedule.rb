require_relative "application" unless defined? Rails # to test node type

if ::Rails.application.is_admin_node?
  every 5.minutes do
    rake 'enqueue_index_jobs'
  end
end
