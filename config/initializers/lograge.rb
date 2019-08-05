Rails.application.configure do
  config.lograge.enabled = true

  #this adds some data to the log that's helpful for graylog
  config.lograge.formatter = Lograge::Formatters::Graylog2.new
  if Rails.env.production?
    config.log_tags = [ :remote_ip ]
  end
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    {
      start_time: (now - event.time).seconds.ago,
      params: event.payload[:params].except(*exceptions)
    }
  end
end
