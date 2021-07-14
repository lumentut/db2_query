class TestQuery < Db2Query::Base
  def all_sql
    "SELECT * FROM DB2INST1.USERS"
  end

  def by_id_sql
    "SELECT * FROM DB2INST1.USERS WHERE $id = ?"
  end

  def by_name_and_email_sql
    "SELECT * FROM DB2INST1.USERS WHERE $first_name = ? AND $email = ?"
  end

  query :by_name_and_email, -> args {
    fetch("SELECT * FROM DB2INST1.USERS WHERE $first_name = ? AND $email = ?", args)
  }

  query :find_by, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id = ?
  SQL

  query :id_gt, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id > ?
  SQL

  query :id_greater_than, -> args {
    fetch("SELECT * FROM DB2INST1.USERS WHERE $id > ?", args)
  }

  query :user_by_ids, -> args {
    fetch_list("SELECT * FROM DB2INST1.USERS WHERE ID IN (@list)", args)
  }

  _SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE @extention", extention)
  }

  __SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE extention", extention)
  }

  query :wrong_list_pointer, -> args {
    fetch_list(
      _SQL.("first_name IN (list)"), args
    )
  }

  query :wrong_extention_pointer, -> args {
    fetch_list(
      __SQL.("first_name IN (@list)"), args
    )
  }

  query :user_by_names, -> args {
    fetch_list(
      _SQL.("first_name IN (@list)"), args
    )
  }

  query :user_by_details, -> args {
    fetch(_SQL.("$first_name = ? AND $email = ?"), args)
  }

  query :user_by_email, _SQL.("$email = ?")

  query :user_by_name, _SQL.("$first_name = ?")

  query :insert_record, -> args {
    exec_query({},
      "INSERT INTO users ($id, $first_name, $last_name, $email) VALUES (?, ?, ?, ?)", args
    )
  }

  query :update_record, <<-SQL
    UPDATE DB2INST1.USERS SET $email = ? WHERE $id = ?
  SQL

  query :delete_record, <<-SQL
    DELETE FROM users WHERE $id = ?
  SQL

  def non_string_sql
    0
  end
end  
