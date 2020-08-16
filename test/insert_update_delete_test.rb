# frozen_string_literal: true

require "models/user"

class InsertUpdateDeleteTest < ActiveSupport::TestCase
  def test_iud
    user_id = 11111
    first_name = "john"
    last_name = "doe"
    email = "john.doe@yahoo.com"

    user_inserted = User.insert_record user_id, first_name, last_name, email
    user_inserted = user_inserted.record

    assert_equal user_inserted.id, user_id
    assert_equal user_inserted.first_name, first_name
    assert_equal user_inserted.last_name, last_name
    assert_equal user_inserted.email, email

    email_updated = "john.doe@gmail.com"
    user_updated = User.update_record email_updated, user_id
    user_updated = user_updated.record

    assert_equal user_updated.id, user_id
    assert_equal user_updated.first_name, first_name
    assert_equal user_updated.last_name, last_name
    assert_equal user_updated.email, email_updated

    user_deleted = User.delete_record user_id
    user_deleted = user_deleted.record

    assert_equal user_deleted.id, user_id
    assert_equal user_deleted.first_name, first_name
    assert_equal user_deleted.last_name, last_name
    assert_equal user_deleted.email, user_updated.email
  end
end
