require_relative "application" unless defined? Rails # to test node type

if ::Rails.application.is_manager_node?
  every 5.minutes do
    rake 'all_manager_jobs'
  end
end
