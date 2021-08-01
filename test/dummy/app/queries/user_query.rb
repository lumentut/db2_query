# frozen_string_literal: true

class UserQuery < Db2Query::Base 
  def all_sql
    "SELECT * FROM USERS"
  end
 
  def by_id_sql
    "SELECT * FROM USERS WHERE $id = ?"
  end
 
  def by_first_name_and_email_sql
    "SELECT * FROM USERS WHERE $first_name = ? AND $email = ?"
  end

  query :by_last_name_and_email, <<-SQL
    SELECT * FROM USERS WHERE $last_name = ? AND $email = ?
  SQL

  query :find_by, <<-SQL
    SELECT * FROM USERS WHERE $id = ?
  SQL

  query :id_gt, <<-SQL
    SELECT * FROM USERS WHERE $id > ?
  SQL

  query :id_greater_than, -> args {
    fetch("SELECT * FROM USERS WHERE $id > ?", args)
  }

  query :by_first_name_and_last_name, -> args {
    fetch("SELECT * FROM USERS WHERE $first_name = ? AND $last_name = ?", args)
  }

  query :by_ids, -> args {
    fetch_list("SELECT * FROM USERS WHERE $first_name LIKE ? AND id IN (@list)", args)
  }

  SQL = -> extention {
    sql_with_extention("SELECT * FROM USERS WHERE @extention", extention)
  }

  query :by_names, -> args {
    fetch_list(
      SQL.("first_name IN (@list)"), args
    )
  }

  query :by_details, -> args {
    fetch(SQL.("$first_name = ? AND $email = ?"), args)
  }

  query :by_email, SQL.("$email = ?")

  query :by_first_name, SQL.("$first_name = ?")  

  query :insert_record, <<-SQL
    INSERT INTO users ($first_name, $last_name, $email) VALUES (?, ?, ?)
  SQL

  query :update_record, -> args {
    exec_query("UPDATE USERS SET $email = ? WHERE $id = ?", args)
  }

  query :delete_record, <<-SQL
    DELETE FROM users WHERE $id = ?
  SQL

  # =================================
  # WRONG IMPLEMENTATION
  # =================================

  query :wrong_list_pointer, -> args {
    fetch_list(
      SQL.("first_name IN (list)"), args
    )
  }

  _SQL = -> extention {
    sql_with_extention("SELECT * FROM USERS WHERE extention", extention)
  }

  query :wrong_extention_pointer, -> args {
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
