# frozen_string_literal: true

class BlankDefinitionsQuery < Db2Query::Base
  query :details, <<-SQL
    SELECT * FROM DEFINITIONS
  SQL
end
