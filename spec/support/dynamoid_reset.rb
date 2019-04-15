module DynamoidReset
  def self.create_all
    Dynamoid.included_models.each { |m| m.create_table(sync: true) }

    tries = 0
    do_not_record_or_playback do
      until tables_created? || tries >= 5 do
        Rails.logger.debug("Waiting for dynamo tables to be created. #{tries} tries.")
        sleep(3)
        tries +=1
      end
    end
  end

  def self.delete_all
    Dynamoid.adapter.list_tables.each do |table|
      if table =~ /^#{Dynamoid::Config.namespace}/
        Dynamoid.adapter.delete_table(table)
      end
    end
    Dynamoid.adapter.tables.clear

    tries = 0
    do_not_record_or_playback do
      until tables_deleted? || tries >= 5 do
        Rails.logger.debug("Waiting for dynamo tables to be deleted. #{tries} tries")
        sleep(3)
        tries += 1
      end
    end
  end

  def self.tables_created?
    Dynamoid.included_models.all? do |m|
      Dynamoid.adapter.list_tables.include? m.table_name
    end
  rescue
    false
  end

  def self.tables_deleted?
    tables_found = Dynamoid.adapter.list_tables.count do |table|
      table =~ /^#{Dynamoid::Config.namespace}/
    end
    tables_found == 0
  rescue
    false
  end
end

# Reduce noise in test output
Dynamoid.logger.level = Logger::FATAL
