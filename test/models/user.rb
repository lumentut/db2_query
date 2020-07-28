# frozen_string_literal: true

class User < DB2Query::Base
  def all_sql
    "SELECT * FROM LIBTEST.USERS"
  end

  def by_id_sql
    "SELECT * FROM LIBTEST.USERS WHERE id = ?"
  end

  query :by_name_and_email, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE first_name = ? AND email = ?
  SQL

  query :find_by, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE id = ?
  SQL

  def insert_record_sql
    "INSERT INTO users (id, first_name, last_name, email)
    VALUES (10010, John, Doe, john.doe@gmail.com)"
  end
end
