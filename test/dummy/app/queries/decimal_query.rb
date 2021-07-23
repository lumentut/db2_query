# frozen_string_literal: true

class DecimalQuery < Db2Query::Base 
  def all_sql
    "SELECT * FROM DECIMALS"
  end

  query :insert, <<-SQL
    INSERT INTO decimals ($name, $data_1, $data_2) VALUES (?, ?, ?)
  SQL
end
