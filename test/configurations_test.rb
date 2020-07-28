# frozen_string_literal: true

require "test_helper"

class ConfigurationsTest < ActiveSupport::TestCase
  def test_empty_returns_true_when_db_configs_are_empty
    old_config = DB2Query::Base.configurations
    config = {}

    DB2Query::Base.configurations = config

    assert_predicate DB2Query::Base.configurations, :empty?
    assert_predicate DB2Query::Base.configurations, :blank?
  ensure
    DB2Query::Base.configurations = old_config
    DB2Query::Base.establish_connection :dqunit
  end

  def test_configs_for_getter_with_env_name
    configs = DB2Query::Base.configurations.configs_for(env_name: "dqunit")

    assert_equal 2, configs.size
    assert_equal ["primary", "secondary"], configs.map(&:spec_name)
  end

  def test_configs_for_getter_with_env_and_spec_name
    config = DB2Query::Base.configurations.configs_for(env_name: "dqunit", spec_name: "primary")

    assert_equal "dqunit", config.env_name
    assert_equal "primary", config.spec_name
  end

  def test_default_hash_returns_config_hash_from_default_env
    original_rails_env = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "dqunit"

    assert_equal DB2Query::Base.configurations.configs_for(env_name: "dqunit", spec_name: "primary").config, DB2Query::Base.configurations.default_hash
  ensure
    ENV["RAILS_ENV"] = original_rails_env
  end

  def test_find_db_config_returns_a_db_config_object_for_the_given_env
    config = DB2Query::Base.configurations.find_db_config("dqunit")

    assert_equal "dqunit", config.env_name
    assert_equal "primary", config.spec_name
  end

  def test_to_h_turns_db_config_object_back_into_a_hash
    configs = DB2Query::Base.configurations
    assert_equal "ActiveRecord::DatabaseConfigurations", configs.class.name
    assert_equal "Hash", configs.to_h.class.name
    assert_equal ["dqunit"], DB2Query::Base.configurations.to_h.keys.sort
  end
end