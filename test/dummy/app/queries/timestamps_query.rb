# frozen_string_literal: true

class TimestampsQuery < Db2Query::Base
  query :all, <<-SQL
    SELECT * FROM TIMESTAMPS
  SQL

  query :insert, <<-SQL
    INSERT INTO timestamps (name, data) VALUES (:name, :data)
  SQL
end
