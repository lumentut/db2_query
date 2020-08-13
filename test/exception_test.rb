# frozen_string_literal: true

require "test_helper"
require "models/user"

class ExceptionTest < ActiveSupport::TestCase
  def test_given_args_bigger_than_expected
    exception = assert_raise(Exception) { User.all 100 }
    assert_equal("wrong number of arguments (given 1, expected 0)", exception.message)

    assert_nothing_raised do
      User.all
    end
  end

  def test_arguments
    user = User.all.records.first

    assert_nothing_raised do
      User.by_name_and_email first_name: user.first_name, email: user.email
    end

    assert_nothing_raised do
      User.by_name_and_email email: user.email, first_name: user.first_name
    end

    assert_nothing_raised do
      User.by_name_and_email user.id, user.email
    end

    users1 = users2 = nil
    assert_nothing_raised do
      users1 = User.id_gt 10005
      users2 = User.id_greater_than 10005
    end

    assert_equal users1.records.length, users2.records.length
    assert_equal users1.to_h, users2.to_h

    exception = assert_raise(Exception) { User.by_name_and_email user.email }
    assert_equal("wrong number of arguments (given 1, expected 2)", exception.message)
  end

  def test_insert
    assert_nothing_raised do
      User.insert_record 10010, "John", "Doe", "john.doe@gmail.com"
      User.delete_id 10010
    end
  end

  def test_non_string
    exception = assert_raise(Exception) { User.non_string }
    assert_equal("Query methods must return a SQL statement string!", exception.message)
  end
end
