# frozen_string_literal: true

class UserQuery < Db2Query::Base
  query_arguments :mailto, { email: :string, trim: true }

  def all_sql
    "SELECT * FROM USERS"
  end
 
  def by_id_sql
    "SELECT * FROM USERS WHERE id = :id"
  end
 
  def by_first_name_and_email_sql
    "SELECT * FROM USERS WHERE first_name = :first_name AND email = :email"
  end

  query :by_last_name_and_email, <<-SQL
    SELECT * FROM USERS WHERE last_name = :last_name AND email = :email
  SQL

  query :find_by, <<-SQL
    SELECT * FROM USERS WHERE id = :id
  SQL

  query :id_gt, <<-SQL
    SELECT * FROM USERS WHERE id > :id
  SQL

  query :id_greater_than, -> args {
    fetch("SELECT * FROM USERS WHERE id > :id", args)
  }

  query :by_first_name_and_last_name, -> args {
    fetch("SELECT * FROM USERS WHERE first_name = :first_name AND last_name = :last_name", args)
  }

  query :by_ids, -> args {
    fetch_list("SELECT * FROM USERS WHERE first_name LIKE :first_name AND id IN (@list)", args)
  }

  SQL = -> extension {
    sql_with_extension("SELECT * FROM USERS WHERE @extension", extension)
  }

  query :by_names, -> args {
    fetch_list(
      SQL.("first_name IN (@list)"), args
    )
  }

  query :by_details, -> args {
    fetch(SQL.("first_name = :first_name AND email = :email"), args)
  }

  query :by_email, SQL.("email = :email")

  query :by_first_name, SQL.("first_name = :first_name")  

  query :mailto, <<-SQL
    SELECT id, first_name, last_name, email AS mailto FROM USERS WHERE email = :email
  SQL

  query :insert_record, <<-SQL
    INSERT INTO users (first_name, last_name, email) VALUES (:first_name, :last_name, :email)
  SQL

  query :update_record, -> args {
    exec_query("UPDATE USERS SET email = :email WHERE id = :id", args)
  }

  query :delete_record, <<-SQL
    DELETE FROM users WHERE id = :id
  SQL

  # =================================
  # WRONG IMPLEMENTATION
  # =================================

  query :wrong_list_pointer, -> args {
    fetch_list(
      SQL.("first_name IN (list)"), args
    )
  }

  _SQL = -> extension {
    sql_with_extension("SELECT * FROM USERS WHERE extension", extension)
  }

  query :wrong_extension_pointer, -> args {
    fetch_list(
      _SQL.("first_name IN (@list)"), args
    )
  }

  def non_string_sql
    0
  end

  def self.wrong_fetch_query
    fetch("SELECT * FROM USERS", [])
  end

  def self.wrong_fetch_list_query
    fetch_list("SELECT * FROM USERS WHERE id IN (@list)", [[10001, 10002, 10003], []])
  end

  def self.wrong_exec_query
    exec_query("SELECT * FROM USERS", [])
  end
end
