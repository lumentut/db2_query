# frozen_string_literal: true

class BooleanQuery < Db2Query::Base 
  def all_sql
    "SELECT * FROM BOOLEANS"
  end

  query :insert, <<-SQL
    INSERT INTO booleans (name, data) VALUES (:name, :data)
  SQL
end
