# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "connection_pool"
require "db2_query"
require "active_support/concurrency/load_interlock_aware_monitor"
require "faker"

ENV["RAILS_ENV"] = "test"
ENV["RAILS_ROOT"] ||= File.dirname(__FILE__) + "/../../../.."

def load_config
  file_path = File.dirname(__FILE__) + "/dummy/config/db2query.yml"
  Db2Query::Base.load_database_configurations file_path
end

SQL_FILES_DIR = "#{Dir.pwd}/test/sql"
CREATE_TABLE_SQL_FILES = Dir[SQL_FILES_DIR + "/create_*"]
INSERT_USERS_SQL_FILE = SQL_FILES_DIR + "/insert_users.sql"
INSERT_USER_SQL = File.read(INSERT_USERS_SQL_FILE)

def prepare_test_database
  puts "Preparing test database ..."

  load_config

  @connection = Db2Query::Base.connection

  # List existing tables
  tables_in_schema = @connection.query_values(
    "SELECT table_name FROM SYSIBM.SQLTABLES
    WHERE table_schem='#{ENV['USER'].upcase}' AND table_type='TABLE'"
  )

  # Delete existing tables
  if tables_in_schema.length > 0 then
    tables_in_schema.each do |table|
      @connection.execute("DROP TABLE #{ENV['USER']}.#{table}")
    end
  end

  # Create tables
  CREATE_TABLE_SQL_FILES.each do |sql_file|
    sql = File.read(sql_file)
    @connection.execute(sql)
  end

  # Populate users
  (10000...10010).each do
    @connection.execute(INSERT_USER_SQL, [Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.email])
  end
end
