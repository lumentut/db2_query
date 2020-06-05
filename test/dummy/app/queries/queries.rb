# frozen_string_literal: true

class Queries < Db2Query::Base
  def user_all_sql
    "SELECT * FROM LIBTEST.USERS"
  end

  def user_find_by_sql
    "SELECT * FROM LIBTEST.USERS WHERE USER_ID = ?"
  end

  def users_where_id_sql
    "SELECT * FROM LIBTEST.USERS WHERE USER_ID BETWEEN ? AND ?"
  end

  query :users_between, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE USER_ID BETWEEN ? AND ?
  SQL

  def non_string_sql
    puts ""
  end
end
