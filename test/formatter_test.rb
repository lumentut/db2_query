# frozen_string_literal: true

require "test_helper"

class FormatterTest < ActiveSupport::TestCase
  setup do
    @user = Users.find_by(10000)
    @formatter = @user.column_metadatas[1].formatter
  end

  def test_formatter
    assert_equal(@user.to_a.first.first_name, @formatter.format(@user.rows.first[1]))
  end
end
