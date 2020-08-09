# frozen_string_literal: true

require "test_helper"
require "odbc_utf8"

class ConnectionPoolTest < ActiveSupport::TestCase
  def test_satu
    DB2Query::Base.connection
  end
end
