# frozen_string_literal: true

require "test_helper"

class DecimalTest < ActiveSupport::TestCase
  test "precision and scale" do
    # decimal = DecimalQuery.insert name: "decimals", data_1: 123.456, data_2: 123456
    # puts decimal.to_h

    puts DecimalQuery.all
  end
end
