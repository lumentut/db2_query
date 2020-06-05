# frozen_string_literal: true

class Users < Db2Query::Base
  attributes :first_name, :first_name_formatter

  def all_sql
    "SELECT * FROM LIBTEST.USERS"
  end

  def between_sql
    "SELECT * FROM LIBTEST.USERS WHERE user_id BETWEEN ? AND ?"
  end

  def drop_table_sql
    "DROP TABLE LIBTEST.USERS"
  end

  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE user_id = ?
  SQL
end
