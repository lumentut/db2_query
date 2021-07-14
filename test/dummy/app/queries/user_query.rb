# frozen_string_literal: true

class UserQuery < Db2Query::Base 
  def all_sql
    "SELECT * FROM DB2INST1.USERS"
  end
 
  def by_id_sql
    "SELECT * FROM DB2INST1.USERS WHERE $id = ?"
  end
 
  def by_first_name_and_email_sql
    "SELECT * FROM DB2INST1.USERS WHERE $first_name = ? AND $email = ?"
  end

  query :by_last_name_and_email, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $last_name = ? AND $email = ?
  SQL

  query :find_by, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id = ?
  SQL

  query :id_gt, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id > ?
  SQL

  query :id_greater_than, -> args {
    fetch("SELECT * FROM DB2INST1.USERS WHERE $id > ?", args)
  }

  query :by_first_name_and_last_name, -> args {
    fetch("SELECT * FROM DB2INST1.USERS WHERE $first_name = ? AND $last_name = ?", args)
  }

  query :by_ids, -> args {
    fetch_list("SELECT * FROM DB2INST1.USERS WHERE $first_name LIKE ? AND id IN (@list)", args)
  }

  SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE @extention", extention)
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

  query :wrong_list_pointer, -> args {
    fetch_list(
      SQL.("first_name IN (list)"), args
    )
  }

  _SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE extention", extention)
  }

  query :wrong_extention_pointer, -> args {
    fetch_list(
      _SQL.("first_name IN (@list)"), args
    )
  }

  def non_string_sql
    0
  end

  query :insert_record, <<-SQL
    INSERT INTO users ($first_name, $last_name, $email) VALUES (?, ?, ?)
  SQL

  query :update_record, <<-SQL
    UPDATE DB2INST1.USERS SET $email = ? WHERE $id = ?
  SQL

  query :delete_record, <<-SQL
    DELETE FROM users WHERE $id = ?
  SQL
end
