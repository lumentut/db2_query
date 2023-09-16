# frozen_string_literal: true

class DateTest < ActiveSupport::TestCase
  test "date serialize and deserialize" do
    today = Date.today

    date_1 = DatesQuery.insert name: "today", data: today
    assert_equal date_1.data, today

    custom_date = "17-08-1945"
    date_2 = DatesQuery.insert name: "independende day", data: custom_date
    assert_equal Date.parse(custom_date), date_2.data

    special_date = "06/07/2008"
    date_3 = DatesQuery.insert name: "happy day", data: special_date

    assert_equal Date.parse(special_date), date_3.data
  end
end
