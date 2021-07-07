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

  query :find_by, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id = ?
  SQL

  query :id_gt, <<-SQL
    SELECT * FROM DB2INST1.USERS WHERE $id > ?
  SQL

  query :id_greater_than, -> id {
    exec_query({}, "SELECT * FROM DB2INST1.USERS WHERE $id > ?", [id])
  }

  query :user_by_ids, -> ids {
    fetch_list("SELECT * FROM DB2INST1.USERS WHERE ID IN (@list)", ids)
  }

  _SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE @extention", extention)
  }

  __SQL = -> extention {
    sql_with_extention("SELECT * FROM DB2INST1.USERS WHERE extention", extention)
  }


  query :wrong_list_pointer, -> names {
    fetch_list(
      _SQL.("first_name IN (list)"), names
    )
  }

  query :wrong_extention_pointer, -> names {
    fetch_list(
      __SQL.("first_name IN (@list)"), names
    )
  }

  query :user_by_names, -> names {
    fetch_list(
      _SQL.("first_name IN (@list)"), names
    )
  }

  query :user_by_details, -> name, email {
    fetch(_SQL.("$first_name = ? AND $email = ?"), [name, email])
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
