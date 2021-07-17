# frozen_string_literal: true

class DefinitionsQuery < Db2Query::Base
  query :details, <<-SQL
    SELECT * FROM DEFINITIONS
  SQL
end
