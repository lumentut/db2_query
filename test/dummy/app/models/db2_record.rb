class Db2Record < ActiveRecord::Base
  self.abstract_class = true

  def self.query(sql, args)
    Db2Query::Base.query(sql, *args)
  end
end
