# frozen_string_literal: true

require "test_helper"

prepare_test_database

class CasesTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Db2Query::VERSION
  end

  test "query definitions" do
    definitions = UserQuery.definitions
    query_name = :all
    query_definition =  definitions.queries.fetch(query_name)
    columns_definition = query_definition.columns
    type_definitions = query_definition.types
    assert_equal query_definition.query_name, query_name
    assert_equal type_definitions.length, columns_definition.length
    assert_equal Db2Query::Type::Integer, type_definitions.values.first.class
    assert columns_definition.values.first.is_a?(Array)
  end

  test "query definitions exception" do
    exception = assert_raise(Exception) { DefinitionsQuery.definitions }
    assert_equal "Not supported `others` data type", exception.message
    exception = assert_raise(Exception) { BlankDefinitionsQuery.definitions }
    definition_class = "Definitions::BlankDefinitionsQueryDefinitions"
    assert_equal "Please describe query definitions at #{definition_class}", exception.message
  end

  test "given args bigger than expected" do
    exception = assert_raise(Exception) { UserQuery.all 100 }
    assert_equal("Wrong number of arguments (given 1, expected 0)", exception.message)

    assert_nothing_raised do
      UserQuery.all
    end
  end

  test "user data available" do
    assert !UserQuery.all.records.empty?
  end

  test "sql select statement" do
    user = UserQuery.all.record

    assert_nothing_raised do
      UserQuery.by_first_name_and_email first_name: user.first_name, email: user.email
    end

    assert_nothing_raised do
      UserQuery.by_first_name_and_email email: user.email, first_name: user.first_name
    end

    assert_nothing_raised do
      UserQuery.by_first_name_and_email user.id, user.email
    end

    users1 = users2 = nil
    assert_nothing_raised do
      users1 = UserQuery.id_gt 10005
      users2 = UserQuery.id_greater_than 10005
    end

    assert_equal users1.records.length, users2.records.length
    assert_equal users1.to_h, users2.to_h

    user_details = UserQuery.by_details user.first_name, user.email
    assert_equal user_details.record.first_name, user.first_name
    assert_equal user_details.record.email, user.email

    user_by_email = UserQuery.by_email user.email
    assert_equal user_by_email.records.first.email, user.email

    user_by_name = UserQuery.by_first_name user.first_name
    assert_equal user_by_email.records.first.first_name, user_by_name.records.first.first_name

    exception = assert_raise(Exception) { UserQuery.by_first_name_and_last_name user.email }
    assert_equal("Wrong number of arguments (given 1, expected 2)", exception.message)

    list = [10000, 10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008, 10009]
    key = "#{user.first_name}%"
    user_by_ids = UserQuery.by_ids list, key

    assert_equal user_by_ids.record.first_name, user.first_name
  end

  test "sql insert update delete" do
    last_id = UserQuery.all.records.last.id
    first_name = "john"
    last_name = "doe"
    email = "john.doe@yahoo.com"

    user_inserted = UserQuery.insert_record first_name, last_name, email

    assert_equal user_inserted.id, last_id + 1
    assert_equal user_inserted.first_name, first_name
    assert_equal user_inserted.last_name, last_name
    assert_equal user_inserted.email, email

    user_id = user_inserted.id

    email_updated = "john.doe@gmail.com"
    user_updated = UserQuery.update_record email_updated, user_id

    assert_equal user_updated.id, user_id
    assert_equal user_updated.first_name, first_name
    assert_equal user_updated.last_name, last_name
    assert_equal user_updated.email, email_updated

    user_deleted = UserQuery.delete_record user_id

    assert_equal user_deleted.id, user_id
    assert_equal user_deleted.first_name, first_name
    assert_equal user_deleted.last_name, last_name
    assert_equal user_deleted.email, user_updated.email
  end

  test "insert records auto increment id" do
    6.times {
      UserQuery.insert_record Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.email
    }
    last_user = UserQuery.all.records.last
    assert_equal 10015, last_user.id
  end

  test "non string argument" do
    exception = assert_raise(Exception) { UserQuery.non_string }
    assert_equal("The query body needs to be callable or is a SQL statement string", exception.message)
  end

  test "extention sql and list input" do
    users = UserQuery.all.records
    user_names = users.map { |record| record.first_name }

    assert_nothing_raised do
      UserQuery.by_names user_names
    end

    user_by_names = UserQuery.by_names user_names

    assert user_by_names.is_a?(Db2Query::Result)
    assert_equal user_by_names.length, user_names.length
  end

  test "wrong extention sql and list input" do
    exception_1 = assert_raise(Exception) { UserQuery.wrong_list_pointer ["john", "doe"] }
    assert_equal "Missing @list pointer at SQL", exception_1.message
    exception_2 = assert_raise(Exception) { UserQuery.wrong_extention_pointer ["john", "doe"] }
    assert_equal "Missing @extention pointer at SQL", exception_2.message
    exception_3 = assert_raise(Exception) { UserQuery.by_ids 10000, 10001 }
    assert_equal "The arguments should be an array of list", exception_3.message
  end

  test "lambda queries exceptions" do
    error_message = "Method `fetch`, `fetch_list`, and `exec_query` can only be implemented inside a lambda query"
    exception_1 = assert_raise(Exception) { UserQuery.wrong_fetch_query }
    assert_equal error_message, exception_1.message
    exception_2 = assert_raise(Exception) { UserQuery.wrong_fetch_list_query }
    assert_equal error_message, exception_2.message
    exception_3 = assert_raise(Exception) { UserQuery.wrong_exec_query }
    assert_equal error_message, exception_3.message
  end
end
