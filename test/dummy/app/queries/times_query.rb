# frozen_string_literal: true

class TimesQuery < Db2Query::Base
  query :all, <<-SQL
    SELECT * FROM TIMES
  SQL

  query :insert, <<-SQL
    INSERT INTO times (name, data) VALUES (:name, :data)
  SQL
end
