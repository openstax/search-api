unless ENV['INDEXING_HTTP_LOGGING'] == 'true'
  Ethon.logger = Logger.new(nil)
end
