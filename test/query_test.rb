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

  SQL = -> extention {
    UserQuery.sql_with_extention("SELECT * FROM USERS WHERE @extention", extention)
  }

  def fetch_list(sql, args)
    query_name = args.last.fetch(:query_name)

    assert_equal :by_first_names, query_name

    users = UserQuery.all.to_h
    user_names = users.map { |user| user[:first_name] }

    assert_equal user_names, args.first

    UserQuery.fetch_list(sql, args)
  end

  test "fetch and fetch list query name" do
    users = UserQuery.all.to_h
    user_names = users.map { |user| user[:first_name] }

    UserQuery.define_query_definitions

    UserQuery.query :by_first_names, -> args {
      fetch_list(
        SQL.("first_name IN (@list)"), args
      )
    }

    users_by_first_names = UserQuery.by_first_names user_names
    assert_equal user_names.length, users_by_first_names.length
  end

  test "fetch query" do
    users = UserQuery.all.to_h
    user_names = users.map { |user| user[:last_name] }

    UserQuery.define_query_definitions

    UserQuery.query :by_last_name, -> args {
      UserQuery.fetch("SELECT * FROM USERS WHERE $last_name = ?", args)
    }

    user = UserQuery.by_last_name user_names.first
    assert_equal user.last_name, user_names.first
  end
end
