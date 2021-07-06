# frozen_string_literal: true

require "test_helper"

class Db2QueryTest < ActiveSupport::TestCase
  setup do
    load_config
  end

  test "it has a version number" do
    assert Db2Query::VERSION
  end

  test "config file loaded" do
    base_config_id = Db2Query::Base.configurations.object_id
    child_config_id = TestQuery.configurations.object_id
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
        assert_equal pool_id, TestQuery.connection.object_id
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
        assert_equal 5, connection.size
        assert_equal 4, connection.available
      end
    }.join

    Thread.new {
      connection.pool do |conn|
        assert_equal thread_conn, conn
      end
    }.join
  end

  test "db client expiration" do
    config = { dsn: 'ARUNIT', idle: 0.04}
    db_client = Db2Query::DbClient.new(config)
    client_1 = db_client.client
    object_id = client_1.object_id
    assert_equal false, db_client.expire?
    sleep 3
    client_2 = db_client.client
    assert_not_equal object_id, client_2.object_id
    sleep 1
    client_3 = db_client.client
    assert_equal client_2.object_id, client_3.object_id
  end

  test "given args bigger than expected" do
    exception = assert_raise(Exception) { TestQuery.all 100 }
    assert_equal("wrong number of arguments (given 1, expected 0)", exception.message)

    assert_nothing_raised do
      TestQuery.all
    end
  end

  test "sql select statement" do
    user = TestQuery.all.records.first

    assert_nothing_raised do
      TestQuery.by_name_and_email first_name: user.first_name, email: user.email
    end

    assert_nothing_raised do
      TestQuery.by_name_and_email email: user.email, first_name: user.first_name
    end

    assert_nothing_raised do
      TestQuery.by_name_and_email user.id, user.email
    end

    users1 = users2 = nil
    assert_nothing_raised do
      users1 = TestQuery.id_gt 10005
      users2 = TestQuery.id_greater_than 10005
    end

    assert_equal users1.records.length, users2.records.length
    assert_equal users1.to_h, users2.to_h

    user_details = TestQuery.user_by_details user.first_name, user.email
    assert_equal user_details.record.first_name, user.first_name
    assert_equal user_details.record.email, user.email

    user_by_email = TestQuery.user_by_email user.email
    assert_equal user_by_email.records.first.email, user.email

    user_by_name = TestQuery.user_by_name user.first_name
    assert_equal user_by_email.records.first.first_name, user_by_name.records.first.first_name

    exception = assert_raise(Exception) { TestQuery.by_name_and_email user.email }
    assert_equal("wrong number of arguments (given 1, expected 2)", exception.message)
  end

  test "sql insert update delete" do
    user_id = 11111
    first_name = "john"
    last_name = "doe"
    email = "john.doe@yahoo.com"

    user_inserted = TestQuery.insert_record [user_id, first_name, last_name, email]
    user_inserted = user_inserted.record

    assert_equal user_inserted.id, user_id
    assert_equal user_inserted.first_name, first_name
    assert_equal user_inserted.last_name, last_name
    assert_equal user_inserted.email, email

    email_updated = "john.doe@gmail.com"
    user_updated = TestQuery.update_record email_updated, user_id
    user_updated = user_updated.record

    assert_equal user_updated.id, user_id
    assert_equal user_updated.first_name, first_name
    assert_equal user_updated.last_name, last_name
    assert_equal user_updated.email, email_updated

    user_deleted = TestQuery.delete_record user_id
    user_deleted = user_deleted.record

    assert_equal user_deleted.id, user_id
    assert_equal user_deleted.first_name, first_name
    assert_equal user_deleted.last_name, last_name
    assert_equal user_deleted.email, user_updated.email
  end

  test "non string argument" do
    exception = assert_raise(Exception) { TestQuery.non_string }
    assert_equal("Query methods must return a SQL statement string!", exception.message)
  end

  test "extention sql and list input" do
    users = TestQuery.all.records
    user_names = users.map { |record| record.first_name }

    records = nil
    assert_nothing_raised do
      records = TestQuery.user_by_names user_names
    end

    assert_equal records.length, user_names.length
  end
end
