# frozen_string_literal: true

require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  def setup
    @handler = DB2Query::ConnectionHandler.new
    @spec_name = "primary"
    @pool = @handler.establish_connection(DB2Query::Base.configurations["dqunit"])
  end

  def test_default_env_fall_back_to_default_env_when_rails_env_or_rack_env_is_empty_string
    original_rails_env = ENV["RAILS_ENV"]
    original_rack_env  = ENV["RACK_ENV"]
    ENV["RAILS_ENV"]   = ENV["RACK_ENV"] = ""

    assert_equal "default_env", ActiveRecord::ConnectionHandling::DEFAULT_ENV.call
  ensure
    ENV["RAILS_ENV"] = original_rails_env
    ENV["RACK_ENV"]  = original_rack_env
  end

  def test_establish_connection_uses_spec_name
    old_config = DB2Query::Base.configurations
    config = { "readonly" => {
      "adapter" => "db2_query",
        "conn_string" => {
          "driver"  => "DB2",
          "database"  => "ARUNIT2",
          "dbalias"  => "ARUNIT2",
          "hostname"  => "LOCALHOST",
          "currentschema"  => "LIBTEST",
          "port"  => "0",
          "protocol"  => "IPC",
          "uid"  =>  ENV["DB2EC_UID"],
          "pwd"  => ENV["DB2EC_PWD"],
        }
      }
    }
    DB2Query::Base.configurations = config
    resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(DB2Query::Base.configurations)
    spec =  resolver.spec(:readonly)
    @handler.establish_connection(spec.to_hash)

    assert_not_nil @handler.retrieve_connection_pool("readonly")
  ensure
    DB2Query::Base.configurations = old_config
    @handler.remove_connection("readonly")
  end

  def test_retrieve_connection
    assert @handler.retrieve_connection(@spec_name)
  end

  def test_active_connections?
    assert_not_predicate @handler, :active_connections?
    assert @handler.retrieve_connection(@spec_name)
    assert_predicate @handler, :active_connections?
    @handler.clear_active_connections!
    assert_not_predicate @handler, :active_connections?
  end

  def test_retrieve_connection_pool
    assert_not_nil @handler.retrieve_connection_pool(@spec_name)
  end

  def test_retrieve_connection_pool_with_invalid_id
    assert_nil @handler.retrieve_connection_pool("foo")
  end

  def test_connection_pools
    assert_equal([@pool], @handler.connection_pools)
  end

  class ApplicationRecord < DB2Query::Base
    self.abstract_class = true
  end

  class MyClass < ApplicationRecord
  end

  def test_connection_specification_name_should_fallback_to_parent
    Object.send :const_set, :ApplicationRecord, ApplicationRecord

    klassA = Class.new(DB2Query::Base)
    klassB = Class.new(klassA)
    klassC = Class.new(MyClass)

    assert_equal klassB.connection_specification_name, klassA.connection_specification_name
    assert_equal klassC.connection_specification_name, klassA.connection_specification_name

    assert_equal "primary", klassA.connection_specification_name
    assert_equal "primary", klassC.connection_specification_name

    klassA.connection_specification_name = "readonly"
    assert_equal "readonly", klassB.connection_specification_name

    DB2Query::Base.connection_specification_name = "readonly"
    assert_equal "readonly", klassC.connection_specification_name
  ensure
    Object.send :remove_const, :ApplicationRecord
    DB2Query::Base.connection_specification_name = "primary"
  end
end
