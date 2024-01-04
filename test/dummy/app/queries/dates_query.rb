# frozen_string_literal: true

class DatesQuery < Db2Query::Base
  query :all, <<-SQL
    SELECT * FROM DATES
  SQL

  query :insert, <<-SQL
    INSERT INTO dates (name, data) VALUES (:name, :data)
  SQL
end
