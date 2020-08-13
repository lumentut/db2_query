# frozen_string_literal: true

require "db2_query/formatter"
require "models/user"

class FormatterTest < ActiveSupport::TestCase
  class FirstNameFormatter < DB2Query::AbstractFormatter
    def format(value)
      "Dr." + value
    end
  end

  class LastNameFormatter < DB2Query::AbstractFormatter
    def format(value)
      value + ", Ph.D."
    end
  end

  DB2Query::Formatter.registration do |format|
    format.register(:first_name_formatter, FirstNameFormatter)
    format.register(:last_name_formatter, LastNameFormatter)
  end

  class Doctor < User
    attributes :first_name, :first_name_formatter
  end

  class DoctorOfPhilosophy < User
    attributes :last_name, :last_name_formatter
  end

  def test_formatting
    user = User.all.records.first
    doctor = Doctor.by_id(user.id).records.first
    assert_equal "Dr.#{user.first_name}", doctor.first_name
    assert_equal user.last_name, doctor.last_name

    user1 = DoctorOfPhilosophy.by_id(user.id).records.first
    assert_equal user.first_name, user1.first_name
    assert_equal "#{user.last_name}, Ph.D.", user1.last_name
  end
end
