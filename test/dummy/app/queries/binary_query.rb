# frozen_string_literal: true

class BinaryQuery < Db2Query::Base 
  def all_sql
    "SELECT * FROM BINARIES"
  end

  query :insert, <<-SQL
    INSERT INTO binaries ($name, $data) VALUES (?, ?)
  SQL
end
