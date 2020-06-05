# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"
require "faker"
require "byebug"

Db2Query::Schema.initiation do
  # connection will be initialize here?
  config.init_connection = true

  # validate current schema
  config.schema = "LIBTEST"

  # directory of tables creation sql
  config.sql_files_dir = "#{Dir.pwd}/test/sql"

  # perform initial tasks
  perform_tasks do
    # drop all tables in schema
    task :drop_tables do
      tables_in_schema.each do |table|
        execute(sql("DROP TABLE #{schema}.#{table}"))
      end
    end

    # create table
    task :create_users_table, file("users.sql")

    # populate users
    task :create_users, file("create_user.sql") do |sql|
      (10000...10021).each do |i|
        execute(sql, i, Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.email)
      end
    end
  end
end
