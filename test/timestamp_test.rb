# frozen_string_literal: true

class TimestampTest < ActiveSupport::TestCase
  test "date serialize and deserialize" do
    time_1 = "2021-07-31-01.02.03.456789"

    timestamp_1 = TimestampsQuery.insert name: "string_timestamp", data: time_1
    assert_equal timestamp_1.data.strftime("%F-%H.%M.%S.%6N"), time_1

    time_2 = Time.now
    timestamp_2 = TimestampsQuery.insert name: "string_timestamp", data: time_2
    assert_equal timestamp_2.data.strftime("%Y-%m-%d.%H.%M.%S.%6N"), time_2.strftime("%Y-%m-%d.%H.%M.%S.%6N")
    assert_equal timestamp_2.data.usec, time_2.usec

    time_3 = DateTime.now
    timestamp_3 = TimestampsQuery.insert name: "string_timestamp", data: time_3
    assert_equal timestamp_3.data.strftime("%Y-%m-%d.%H.%M.%S.%6N"), time_3.strftime("%Y-%m-%d.%H.%M.%S.%6N")
    assert_equal timestamp_3.data.usec, time_3.usec
  end
end
