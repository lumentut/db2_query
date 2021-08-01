class User < Db2Record
  scope :by_name, -> *args {
    query("SELECT * FROM USERS WHERE $first_name = ? AND $last_name = ?", args)
  }
end
