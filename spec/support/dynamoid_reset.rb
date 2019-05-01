class DynamoidReset

  TABLE_NAME = "test_indexing"

  KEY_SCHEMA = [
    { attribute_name: 'book_version_id',  key_type: 'HASH' },
    { attribute_name: 'indexing_version', key_type: 'RANGE' }
  ]

  ATTRIBUTE_DEFINITIONS =
    [
      { attribute_name: "book_version_id",  attribute_type: "S" },
      { attribute_name: "indexing_version", attribute_type: "S" },
    ]

  REQUEST = {
    attribute_definitions:    ATTRIBUTE_DEFINITIONS,
    table_name:               TABLE_NAME,
    key_schema:               KEY_SCHEMA,
    provisioned_throughput:   { read_capacity_units: 2, write_capacity_units: 2 }
  }

  def create
    client.create_table(REQUEST)
    client.wait_until(:table_exists, table_name: TABLE_NAME)
  end

  def delete
    client.delete_table({ table_name: TABLE_NAME})
    client.wait_until(:table_not_exists, table_name: TABLE_NAME)
  end

  private

  def client
    @client ||= Aws::DynamoDB::Client.new(region: ENV['REGION'])
  end

  def tablename
    Rails.application.secrets.dynamodb[:index_state_table_name]
  end
end

# Reduce noise in test output
Dynamoid.logger.level = Logger::FATAL
