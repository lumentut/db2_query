# frozen_string_literal: true

require "test_helper"

class Db2QueryTest < ActiveSupport::TestCase
  setup do
    load_config
  end

  test "it has a version number" do
    assert Db2Query::VERSION
  end

  test "load database config exception" do
    exception = assert_raise(Exception) { Db2Query::Base.load_database_configurations "fake" }
    assert_equal("No such file or directory @ rb_sysopen - fake", exception.message)

    assert_nothing_raised do
      Db2Query::Base.load_database_configurations
    end
  end

  test "load database configurations" do
    base_config_id = Db2Query::Base.configurations.object_id
    child_config_id = UserQuery.configurations.object_id
    assert_equal base_config_id, child_config_id

    config = Db2Query::Base.configurations
    assert_equal Hash, config.class
    assert_equal 4, config.size
    assert_equal [:dsn, :idle, :pool, :timeout], config.keys.sort
  end

  test "thread safe connection" do
    threads = []
    pool_id = Db2Query::Base.connection.object_id
    50.times {
      threads << Thread.new {
        assert_equal pool_id, UserQuery.connection.object_id
      }
    }
    threads.each(&:join)
  end

  test "connection pool" do
    thread_conn = nil
    connection = Db2Query::Base.connection

    Thread.new {
      connection.pool do |conn|
        thread_conn = conn
        expected_state = { size: 5, available: 4 }
        assert_equal expected_state, connection.current_state
      end
    }.join

    Thread.new {
      connection.pool do |conn|
        assert_equal thread_conn, conn
      end
    }.join
  end

  test "db client expiration" do
    config = { dsn: "ARUNIT", idle: 0.04 }
    db_client = Db2Query::DbClient.new(config)
    client_1 = db_client.client
    assert_equal false, db_client.expire?
    sleep 3
    assert_equal true, db_client.expire?
    client_2 = db_client.client
    assert_not_equal client_1.object_id, client_2.object_id
    sleep 1
    assert_equal client_2, db_client.client
    client_3 = db_client.client
    assert_equal client_2.object_id, client_3.object_id
    client_3.disconnect
    assert_not_equal client_3.object_id, db_client.client
  end

  test "db client dsn exception" do
    config = { dsn: "FAKE", idle: 0.04 }
    exception = assert_raise(Exception) { Db2Query::DbClient.new(config) }
    assert_includes exception.message, "Data source name not found"
  end

  test "connection reload" do
    assert_nothing_raised do
      Db2Query::Base.connection.reload
    end
  end

  test "given args bigger than expected" do
    exception = assert_raise(Exception) { UserQuery.all 100 }
    assert_equal("Wrong number of arguments (given 1, expected 0)", exception.message)

    assert_nothing_raised do
      UserQuery.all
    end
  end

  test "sql select statement" do
    user = UserQuery.all.records.first

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
    user_inserted = user_inserted.record

    assert_equal user_inserted.id, last_id + 1
    assert_equal user_inserted.first_name, first_name
    assert_equal user_inserted.last_name, last_name
    assert_equal user_inserted.email, email

    user_id = user_inserted.id

    email_updated = "john.doe@gmail.com"
    user_updated = UserQuery.update_record email_updated, user_id
    user_updated = user_updated.record

    assert_equal user_updated.id, user_id
    assert_equal user_updated.first_name, first_name
    assert_equal user_updated.last_name, last_name
    assert_equal user_updated.email, email_updated

    user_deleted = UserQuery.delete_record user_id
    user_deleted = user_deleted.record

    assert_equal user_deleted.id, user_id
    assert_equal user_deleted.first_name, first_name
    assert_equal user_deleted.last_name, last_name
    assert_equal user_deleted.email, user_updated.email
  end

  test "non string argument" do
    exception = assert_raise(Exception) { UserQuery.non_string }
    assert_equal("The query body needs to be callable or is a SQL statement string", exception.message)
  end

  test "extention sql and list input" do
    users = UserQuery.all.records
    user_names = users.map { |record| record.first_name }

    records = nil
    assert_nothing_raised do
      records = UserQuery.by_names user_names
    end

    assert_equal records.length, user_names.length
  end

  test "wrong extention sql and list input" do
    exception_1 = assert_raise(Exception) { UserQuery.wrong_list_pointer ["john", "doe"] }
    assert_equal "Missing @list pointer at SQL", exception_1.message
    exception_2 = assert_raise(Exception) { UserQuery.wrong_extention_pointer ["john", "doe"] }
    assert_equal "Missing @extention pointer at SQL", exception_2.message
  end

  test "lambda queries methods" do
    error_message = "Method `fetch`, `fetch_list`, and `exec_query` can only be implemented inside a lambda query"
    exception_1 = assert_raise(Exception) { UserQuery.wrong_fetch_query }
    assert_equal error_message, exception_1.message
    exception_2 = assert_raise(Exception) { UserQuery.wrong_fetch_list_query }
    assert_equal error_message, exception_2.message
    exception_3 = assert_raise(Exception) { UserQuery.wrong_exec_query }
    assert_equal error_message, exception_3.message
  end
end
