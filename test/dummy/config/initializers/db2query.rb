# frozen_string_literal: true

# Example
require "db2_query/formatter"

class FirstNameFormatter < Db2Query::AbstractFormatter
  def format(value)
    "First Name: " + value
  end
end

Db2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
