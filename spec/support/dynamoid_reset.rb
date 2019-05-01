module DynamoidReset
  def self.create
    self.delete
    Dynamoid.adapter.tables.clear

    BookIndexing.create_table(sync: true)
  end

  def self.delete
    if Dynamoid.adapter.list_tables.include?(tablename)
      Dynamoid.adapter.delete_table(tablename)
    end
  end

  def self.tablename
    Rails.application.secrets.dynamodb[:index_state_table_name]
  end
end

# Reduce noise in test output
Dynamoid.logger.level = Logger::FATAL
