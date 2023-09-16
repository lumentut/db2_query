# frozen_string_literal: true

class ConnectionTest < ActiveSupport::TestCase
  setup do
    Db2Query::Base.establish_connection
  end

  test "connection initiation shutdown and reload" do
    @connection = Db2Query::Base.connection
    assert @connection.is_a?(Db2Query::Connection)

    @connection.pool do |db_client|
      assert db_client.is_a?(Db2Query::DbClient)
      client = db_client.new_client
      assert client.is_a?(ODBC::Database)
    end

    @connection.execute("SELECT * FROM USERS")

    @connection.disconnect!

    exception = assert_raise(Exception) { @connection.pool { |db_client| db_client } }
    assert_equal("ConnectionPool::PoolShuttingDownError", exception.message)

    assert_nothing_raised do
      @connection.reload

      @connection.pool do |db_client|
        assert db_client.is_a?(Db2Query::DbClient)
        assert db_client.active?
        @connection.execute("SELECT * FROM USERS")
      end
    end
  end

  test "connection reload" do
    assert_nothing_raised do
      Db2Query::Base.connection.reload
    end
  end

  test "thread safe connection" do
    threads = []
    pool_id = Db2Query::Base.connection.connection_pool.object_id
    50.times {
      threads << Thread.new {
        assert_equal pool_id, UserQuery.connection.connection_pool.object_id
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
    config = { dsn: "LIBTEST", idle: 0.04 }
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
end
