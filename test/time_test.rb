# frozen_string_literal: true

require "test_helper"

class TimeTest < ActiveSupport::TestCase
  test "time serialize and deserialize" do
    now = Time.now
    now_time = TimesQuery.insert name: "current", data: now
    assert_equal now_time.data, now.strftime("%H:%M:%S")

    time_1 = "01.02.03"
    time_1_result = TimesQuery.insert name: "time_1", data: time_1
    assert_equal time_1_result.data, eval(time_1_result.name).tr(".", ":")

    time_2 = "01:02:03"
    time_2_result = TimesQuery.insert name: "time_2", data: time_2
    assert_equal time_2_result.data, eval(time_2_result.name)
  end
end
