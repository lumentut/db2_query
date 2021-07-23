# frozen_string_literal: true

require "test_helper"

class QueryTest < ActiveSupport::TestCase
  attr_reader :user

  setup do
    @user = UserQuery.new
  end

  test "basic query works" do
    sql = user.all_sql

    assert_nothing_raised do
      UserQuery.query :all, sql
    end

    query = UserQuery.definitions.lookup(:all)

    query.define_sql("FAKE SQL")

    assert_equal query.sql, sql

    assert_equal 4, query.length
    assert_equal [], query.keys
    assert !query.column_id.nil?

    exception = assert_raise(Exception) {
      query.validate_result_columns(["id", "first_name", "last_name", "email", "remarks"])
    }

    assert_equal "Wrong number of columns (query definitions 4, query result 5)", exception.message
  end

  test "query 1 arguments" do
    sql = user.by_id_sql

    assert_nothing_raised do
      UserQuery.query :by_id, sql
    end

    query = UserQuery.definitions.lookup(:by_id)

    assert_equal 0, query.sql.scan(/\$\S+/).length
    assert_equal [:id], query.keys
  end

  test "query 2 arguments" do
    sql = user.by_first_name_and_email_sql

    assert_nothing_raised do
      UserQuery.query :by_first_name_and_email, sql
    end

    query = UserQuery.definitions.lookup(:by_first_name_and_email)

    assert_equal 0, query.sql.scan(/\$\S+/).length
    assert_equal [:first_name, :email], query.keys

    query.keys.each do |key|
      assert_equal Db2Query::Type::Text, query.data_type(key).class
    end

    exception = assert_raise(Exception) { query.data_type(:fake) }
    assert_equal "No column fake found at query: by_first_name_and_email definitions", exception.message

    first_name = "John"
    email = "john@doe.com"

    sorted_args = query.serialized_args({ email: email, first_name: first_name })
    assert_equal [first_name, email], sorted_args
  end

  def fetch(sql, args)
    assert_equal "FETCH SQL", sql

    placeholder = args.pop
    query_name = placeholder.fetch(:query_name)

    assert_equal :by_names, query_name

    users = UserQuery.all.to_h
    user_names = users.map { |user| user[:first_name] }

    assert_equal user_names, args.first
  end

  test "fetch query" do
    users = UserQuery.all.to_h
    user_names = users.map { |user| user[:first_name] }

    UserQuery.query :by_names, -> args {
      fetch("FETCH SQL", args)
    }

    UserQuery.by_names user_names
  end
end
