module DynamoidReset
  def self.create
    tries = 0
    until table_deleted? || tries >= 5 do
      puts("Sleeping for #{tablename} to be deleted. #{tries} tries")
      sleep(15)
      tries += 1
    end

    BookIndexing.create_table(sync: true)  #there is no sync: true for delete tho....

    tries = 0
    until table_created? || tries >= 5 do
      puts("Sleeping for #{tablename} to be created. #{tries} tries.")
      sleep(5)
      tries +=1
    end
  end

  def self.table_created?
    tables = Dynamoid.adapter.list_tables
    puts "Checking for table_created? found Dynamo tables - '#{tables.join(', ')}'"
    tables.include? BookIndexing.table_name
  rescue
    false
  end

  def self.table_deleted?
    tables = Dynamoid.adapter.list_tables
    puts "Checking for table_deleted? found Dynamo tables - '#{tables.join(', ')}'"
    tables.exclude? BookIndexing.table_name
  rescue
    false
  end

  def self.delete
    Dynamoid.adapter.delete_table(tablename)
    Dynamoid.adapter.tables.clear    #clear the table cache
  end

  def self.tablename
    Rails.application.secrets.dynamodb[:index_state_table_name]
  end
end

# Reduce noise in test output
Dynamoid.logger.level = Logger::FATAL
