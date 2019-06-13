class DynamoidReset
  delegate :table_name, to: :class

  def self.table_name
    Rails.application.secrets.dynamodb[:index_state_table_name]
  end

  KEY_SCHEMA =
    [
      { attribute_name: 'book_version_id',        key_type: 'HASH' },
      { attribute_name: 'indexing_strategy_name', key_type: 'RANGE' }
    ]

  ATTRIBUTE_DEFINITIONS =
    [
      { attribute_name: "book_version_id",        attribute_type: "S" },
      { attribute_name: "indexing_strategy_name", attribute_type: "S" },
    ]

  REQUEST =
    {
      attribute_definitions:    ATTRIBUTE_DEFINITIONS,
      table_name:               table_name,
      key_schema:               KEY_SCHEMA,
      provisioned_throughput:   { read_capacity_units: 2, write_capacity_units: 2 }
    }

  def create
    client.create_table(REQUEST)
    client.wait_until(:table_exists, {table_name: table_name}, wait_until_options)
  end

  def delete
    client.delete_table({ table_name: table_name})
    client.wait_until(:table_not_exists, {table_name: table_name}, wait_until_options)
  end

  private

  def client
    @client ||= Aws::DynamoDB::Client.new(region: ENV['REGION'])
  end

  def wait_until_options
    if VCR.current_cassette.try!(:recording?)
      {}
    else
      { delay: 0 }
    end
  end
end

# Reduce noise in test output
Dynamoid.logger.level = Logger::FATAL
