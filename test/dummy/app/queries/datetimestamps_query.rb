# frozen_string_literal: true

class DatetimestampsQuery < Db2Query::Base
  query :all, <<-SQL
    SELECT * FROM DATETIMESTAMPS
  SQL

  query :insert, <<-SQL
    INSERT INTO datetimestamps ($name, $date, $time, $timestamp) VALUES (?, ?, ?, ?)
  SQL
end
