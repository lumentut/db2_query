# frozen_string_literal: true

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

    exception = assert_raise(Exception) { User.by_name_and_email user.email }
    assert_equal("wrong number of arguments (given 1, expected 2)", exception.message)
  end

  def test_not_implemented
    exception = assert_raise(Exception) { User.insert_record }
    assert_equal("NotImplementedError", exception.message)
  end
end
