# frozen_string_literal: true

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

    # query.define_sql("SELECT * FROM LIBTEST.USER")

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

    assert_equal 0, query.sql.scan(/\:\S+/).length
    assert_equal ['id'], query.keys
  end

  test "query 2 arguments" do
    sql = user.by_first_name_and_email_sql

    assert_nothing_raised do
      UserQuery.query :by_first_name_and_email, sql
    end

    query = UserQuery.definitions.lookup(:by_first_name_and_email)

    assert_equal 0, query.sql.scan(/\:\S+/).length
    assert_equal ['first_name', 'email'], query.keys

    query.keys.each do |key|
      assert_equal Db2Query::Type::String, query.data_type(key).class
    end

    exception = assert_raise(Exception) { query.data_type(:fake) }
    assert_equal "No column fake found at query: by_first_name_and_email definitions", exception.message

    first_name = "John"
    email = "john@doe.com"

    sorted_args = query.sorted_args({ email: email, first_name: first_name })
    assert_equal [first_name, email], sorted_args
  end

  SQL = -> extension {
    UserQuery.sql_with_extension("SELECT * FROM USERS WHERE @extension", extension)
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
      UserQuery.fetch("SELECT * FROM USERS WHERE last_name = :last_name", args)
    }

    user = UserQuery.by_last_name user_names.first
    assert_equal user.last_name, user_names.first

    exception = assert_raise(Exception) {
      UserQuery.query :insert_fetch, -> args {
        UserQuery.fetch("INSERT INTO users (first_name, last_name, email) VALUES (:first_name, :last_name, :email)", args)
      }
      UserQuery.insert_fetch first_name: user.first_name, last_name: user.last_name, email: user.email
    }

    assert_equal "Fetch queries are used for select statement query only.", exception.message
  end

  test "raw query" do
    users = UserQuery.all

    user = users.record
    query_1 = Db2Query::Base.query("SELECT * FROM USERS WHERE first_name = :first_name AND email = :email", user.first_name, user.email)
    assert_equal query_1.first[:first_name], user.first_name
    assert_equal query_1.first[:email], user.email

    query_2 = Db2Query::Base.query("SELECT * FROM USERS WHERE first_name = :first_name AND email = :email", email: user.email, first_name: user.first_name)
    assert_equal query_2.first[:first_name], user.first_name
    assert_equal query_2.first[:email], user.email

    query_3 = Db2Query::Base.query("SELECT * FROM USERS")
    assert_equal users.to_h, query_3

    exception = assert_raise(Exception) {
      Db2Query::Base.query("SELECT * FROM USERS WHERE first_name = :first_name AND email = :email", email: user.email)
    }

    assert_equal "Wrong number of arguments (given 1, expected 2)", exception.message
  end

  test "rails collaboration" do
    users = UserQuery.all
    user_1 = users.record
    user_2 = User.by_name last_name: user_1.last_name, first_name: user_1.first_name

    assert_equal user_1.id, user_2.first[:id]
  end
end
