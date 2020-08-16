# frozen_string_literal: true

class User < DB2Record
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

  query :id_gt, <<-SQL
    SELECT * FROM LIBTEST.USERS WHERE id > ?
  SQL

  query :id_greater_than, -> id {
    exec_query({}, "SELECT * FROM LIBTEST.USERS WHERE id > ?", [id])
  }

  query :insert_record, <<-SQL
    INSERT INTO users (id, first_name, last_name, email) VALUES (?, ?, ?, ?)
  SQL

  query :update_record, <<-SQL
    UPDATE LIBTEST.USERS SET email = ? WHERE id = ?
  SQL

  query :delete_record, <<-SQL
    DELETE FROM users WHERE id = ?
  SQL

  def non_string_sql
    0
  end
end
