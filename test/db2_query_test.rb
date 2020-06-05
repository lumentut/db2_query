# frozen_string_literal: true

require "test_helper"

class Db2QueryTest < ActiveSupport::TestCase
  test "it has a version_number" do
    refute_nil ::Db2Query::VERSION
  end

  test "it has base class" do
    refute_nil Db2Query::Base
    assert_kind_of Class, Db2Query::Base
  end

  test "it has column class" do
    refute_nil Db2Query::Column
    assert_kind_of Class, Db2Query::Column
  end

  test "it has connection class" do
    refute_nil Db2Query::Connection
    assert_kind_of Class, Db2Query::Connection
  end

  test "it has odbc connector class" do
    refute_nil Db2Query::ODBCConnector
    assert_kind_of Class, Db2Query::ODBCConnector
  end

  test "it has result class" do
    refute_nil Db2Query::Result
    assert_kind_of Class, Db2Query::Result
  end

  test "it has database configuration module" do
    refute_nil Db2Query::DatabaseConfigurations
    assert_kind_of Module, Db2Query::DatabaseConfigurations
  end

  test "it has connection handling module" do
    refute_nil Db2Query::ConnectionHandling
    assert_kind_of Module, Db2Query::ConnectionHandling
  end

  test "it has error constant" do
    refute_nil Db2Query::Error
  end
end
