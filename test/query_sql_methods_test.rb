# frozen_string_literal: true

require "models/user"

class QuerySqlMethodsTest < ActiveSupport::TestCase
  def users
    @users ||= User.all
  end

  def users_first
    @users_first ||= User.find_by id: 10000
  end

  def users_last
    @users_last ||= User.by_id id: 10009
  end

  def test_sql_method
    assert_equal 10, users.length
    assert_equal users_first.records[0].first_name, users.records.first.first_name
    assert_equal users_last.records[0].last_name, users.records.last.last_name
  end

  def test_user_two_input
    user = users_first.records.first
    user_by_name_and_email = User.by_name_and_email first_name: user.first_name, email: user.email
    user_found = user_by_name_and_email.records.first
    assert_equal user_found.first_name, user.first_name
    assert_equal user_found.last_name, user.last_name
    assert_equal user_found.email, user.email
  end
end
