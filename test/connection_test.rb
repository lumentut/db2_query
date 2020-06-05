# frozen_string_literal: true

require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  test "it can read all databases provided" do
    databases = Db2Query::Base.configurations_databases
    assert_equal ["primary", "secondary"], databases
  end

  test "subclass get all databases provided" do
    databases = ConnectionModel.configurations_databases
    assert_equal ["primary", "secondary"], databases
  end

  test "base class get preset database" do
    assert_equal :primary, Db2Query::Base.current_database
  end

  test "subclass and baseclass connection do not interfere with each other" do
    assert_equal :primary, ConnectionModel.current_database

    ConnectionModel.establish_connection :secondary

    assert_equal :primary, Db2Query::Base.current_database
    assert_equal :secondary, ConnectionModel.current_database

    Db2Query::Base.connection.connect
    assert Db2Query::Base.connection.active?

    Db2Query::Base.connection.disconnect!
    assert !Db2Query::Base.connection.active?
    assert ConnectionModel.connection.active?

    Db2Query::Base.connection.reconnect!
    assert Db2Query::Base.connection.active?

    ConnectionModel.connection.connect
    assert ConnectionModel.connection.active?

    ConnectionModel.connection.disconnect!
    assert !ConnectionModel.connection.active?
    assert Db2Query::Base.connection.active?

    ConnectionModel.connection.reconnect!
    assert ConnectionModel.connection.active?

    assert_equal :primary, Db2Query::Base.current_database
    assert_equal :secondary, ConnectionModel.current_database

    Db2Query::Base.clear_connection
    assert_not_equal nil, ConnectionModel.connection

    Db2Query::Base.establish_connection :primary
    ConnectionModel.establish_connection :primary
    assert_equal Db2Query::Base.current_database, ConnectionModel.current_database
  end
end
