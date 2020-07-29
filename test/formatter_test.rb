# frozen_string_literal: true

require "db2_query/formatter"
require "models/user"

class FormatterTest < ActiveSupport::TestCase
  class FirstNameFormatter < DB2Query::AbstractFormatter
    def format(value)
      "Dr." + value
    end
  end

  DB2Query::Formatter.registration do |format|
    format.register(:first_name_formatter, FirstNameFormatter)
  end

  class Doctor < User
    attributes :first_name, :first_name_formatter
  end

  def test_formatting
    user = User.all.records.first
    doctor = Doctor.by_id(user.id).records.first
    assert_equal "Dr.#{user.first_name}", doctor.first_name
  end
end
