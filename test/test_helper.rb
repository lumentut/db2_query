# frozen_string_literal: true

ENV["RAILS_ENV"] = "dqunit"
ENV["DQ_CONFIG_PATH"] = __dir__ + "/config.yml"

require "minitest/autorun"
require "faker"
require "db2_query"
require "byebug"

puts "Testing DB2Query"
DB2Query::Base.initiation do |base|
  base.configurations = DB2Query.config
  base.establish_connection :dqunit
end

class DB2Record < DB2Query::Base
  self.abstract_class = true
end

SQL_FILES_DIR = "#{Dir.pwd}/test/sql"
CREATE_USER_SQL_FILE = SQL_FILES_DIR + "/create_users.sql"
INSERT_USER_SQL_FILE = SQL_FILES_DIR + "/insert_user.sql"

@connection = DB2Query::Base.connection

def tables_in_schema
  @connection.query_values <<-SQL
    SELECT table_name FROM SYSIBM.SQLTABLES
    WHERE table_schem='LIBTEST' AND table_type='TABLE'
  SQL
end

tables_in_schema.each do |table|
  @connection.execute("DROP TABLE LIBTEST.#{table}")
end

def sql(sql_file)
  File.read("#{sql_file}")
end

@connection.execute(sql(CREATE_USER_SQL_FILE))

(10000...10010).each do |i|
  @connection.execute(sql(INSERT_USER_SQL_FILE), [i, Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.email])
end
