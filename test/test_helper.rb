# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "connection_pool"
require "db2_query"
require "active_support/concurrency/load_interlock_aware_monitor"
require "faker"
require "tty-progressbar"

def load_config
  file_path = File.dirname(__FILE__) + "/dummy/config/db2query.yml"
  Db2Query::Base.load_database_configurations file_path
end

SQL_FILES_DIR = "#{Dir.pwd}/test/sql"
CREATE_TABLE_SQL_FILES = Dir[SQL_FILES_DIR + "/create_*"]
INSERT_USERS_SQL_FILE = SQL_FILES_DIR + "/insert_users.sql"
INSERT_USER_SQL = File.read(INSERT_USERS_SQL_FILE)

def prepare_test_database
  load_config

  @connection = Db2Query::Base.connection

  db_info = @connection.query("select * from sysibmadm.env_inst_info").first

  puts "Db2 Version     : #{db_info[5]}"
  puts "Instance Owner  : #{db_info[0]}"
  puts "Run environment : --#{ENV["RAILS_ENV"]}"
  puts ""
  puts "# Preparing:"
  puts ""

  # List existing tables
  tables_in_schema = @connection.query_values(
    "SELECT table_name FROM SYSIBM.SQLTABLES
    WHERE table_schem='#{ENV['USER'].upcase}' AND table_type='TABLE'"
  )

  total = tables_in_schema.length + CREATE_TABLE_SQL_FILES.length + 10

  bar = TTY::ProgressBar.new(":bar",
    bar_format: :dot,
    total: total
  )

  current = 0

  # Delete existing tables
  if tables_in_schema.length > 0 then
    tables_in_schema.each do |table|
      @connection.execute("DROP TABLE #{ENV['USER']}.#{table}")
      current += 1
      bar.current = current
    end
  end

  # Create tables
  CREATE_TABLE_SQL_FILES.each do |sql_file|
    sql = File.read(sql_file)
    @connection.execute(sql)
    current += 1
    bar.current = current
  end

  # Populate users
  (10000...10010).each do
    @connection.execute(INSERT_USER_SQL, [Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.email])
    current += 1
    bar.current = current
  end
  puts ""
end
