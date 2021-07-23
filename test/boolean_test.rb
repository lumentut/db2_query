# frozen_string_literal: true

require "test_helper"

class BooleanTest < ActiveSupport::TestCase
  test "boolean options" do
    query = BooleanQuery.definitions.lookup(:all)
    assert_equal :T, query.data_type(:data).deserialize(1)

    query = BooleanQuery.definitions.lookup(:insert)
    assert_equal true, query.data_type(:data).deserialize(1)
  end

  test "boolean defaults" do
    OPTIONS = [
      { true: true, false: false },
      { true: 1, false: 0 },
      { true: "1", false: "0" },
      { true: "t", false: "f" },
      { true: "T", false: "F" },
      { true: "true", false: "false" },
      { true: "TRUE", false: "FALSE" },
      { true: "on", false: "off" },
      { true: "ON", false: "OFF" },
      { true: :"1", false: :"0" },
      { true: :t, false: :f },
      { true: :T, false: :F },
      { true: :true, false: :false },
      { true: :TRUE, false: :FALSE },
      { true: :on, false: :off },
      { true: :ON, false: :OFF }
    ]

    OPTIONS.each do |default|
      boolean = Db2Query::Type::Boolean.new(default)
      OPTIONS.each do |options|
        assert_equal 1, boolean.serialize(options[:true])
        assert_equal 0, boolean.serialize(options[:false])
        assert_equal default[:true], boolean.deserialize(1)
        assert_equal default[:false], boolean.deserialize(0)
      end
    end
  end

  test "query class" do
    boolean_true = BooleanQuery.insert name: "true", data: true
    assert_equal boolean_true.name, boolean_true.data.to_s
    boolean_false = BooleanQuery.insert name: "false", data: false
    assert_equal boolean_false.name, boolean_false.data.to_s

    booleans = BooleanQuery.all.records

    booleans.each do |boolean|
      case boolean.name
      when true.to_s
        assert_equal :T, boolean.data
      else
        assert_equal :F, boolean.data
      end
    end
  end
end
