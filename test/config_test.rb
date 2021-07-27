# frozen_string_literal: true

require "test_helper"

class ConfigTest < ActiveSupport::TestCase
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
end
