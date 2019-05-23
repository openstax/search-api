task :all_manager_jobs => :environment do
  Rake::Task['enqueue_index_jobs'].invoke
  Rake::Task['monitor_index_jobs'].invoke
end
