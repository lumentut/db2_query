# frozen_string_literal: true
require "db2_query"
# require "db2_query/formatter"

Db2Query::Base.initiation do |base|
  base.establish_connection
end

# Example
#class FirstNameFormatter < Db2Query::AbstractFormatter
#  def format(value)
#    "Dr." + value
#  end
#end

#Db2Query::Formatter.registration do |format|
#  format.register(:first_name_formatter, FirstNameFormatter)
#end
