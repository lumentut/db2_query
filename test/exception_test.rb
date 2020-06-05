# frozen_string_literal: true

require "test_helper"

class ExceptionTest < ActiveSupport::TestCase
  setup do
    Queries.establish_connection :secondary
  end

  def test_given_args_bigger_than_expected
    exception = assert_raise(Exception) { Queries.user_all 100 }
    assert_equal("wrong number of arguments (given 1, expected 0)", exception.message)

    assert_nothing_raised do
      Queries.user_all
    end
  end

  def test_question_marks
    exception = assert_raise(Exception) { Queries.user_find_by }
    assert_equal("wrong number of arguments (given 0, expected 1)", exception.message)

    assert_nothing_raised do
      Queries.user_find_by 10000
    end

    exception = assert_raise(Exception) { Queries.users_where_id }
    assert_equal("wrong number of arguments (given 0, expected 2)", exception.message)

    assert_nothing_raised do
      Queries.users_where_id 10000, 10001
      Queries.users_between 10000, 10009
    end
  end

  def test_non_string
    exception = assert_raise(Exception) { Queries.non_string }
    assert_equal("Query methods must return a SQL statement string!", exception.message)
  end

  def test_method_exists
    query_name = :find_by
    sql = "SELECT * FROM LIBTEST.USERS WHERE user_id = ?"
    exception = assert_raise(Exception) { Users.query query_name, sql }
    assert_equal("Query :#{query_name} has been defined before", exception.message)
  end

  def test_non_query
    query_name = :non_query
    sql = <<-SQL
      INSERT INTO users (user_id, first_name, last_name, email)
      VALUES (?, ?, ?, ?)
    SQL
    exception = assert_raise(Exception) { Users.query query_name, sql }
    assert_equal("Query only for SQL query commands.", exception.message)
  end

  def test_non_query_sql
    exception = assert_raise(NotImplementedError) { Users.drop_table }
    assert_equal(NotImplementedError, exception.class)
  end

  def test_nothing_raised
    assert_nothing_raised do
      Users.all
      Users.between 10000, 10010
    end
  end
end
