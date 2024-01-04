require "db2_query/version"
require "db2_query/railtie"
require "connection_pool"
require "odbc_utf8"
require "db2_query/error"

module Db2Query
  # Your code goes here...
  autoload :Version, "db2_query/version"
  autoload :Error, "db2_query/error"
  autoload :Config, "db2_query/config"
  autoload :Logger, "db2_query/logger"
  autoload :DbClient, "db2_query/db_client"
  autoload :DbStatements, "db2_query/db_statements"
  autoload :Validations, "db2_query/validations"
  autoload :Helper, "db2_query/helper"
  autoload :Quoting, "db2_query/quoting"
  autoload :FieldType, "db2_query/field_type"

  module Type
    autoload :Value, "db2_query/type/value"
    autoload :Binary, "db2_query/type/binary"
    autoload :Boolean, "db2_query/type/boolean"
    autoload :Decimal, "db2_query/type/decimal"
    autoload :String, "db2_query/type/string"
    autoload :Text, "db2_query/type/text"
    autoload :Integer, "db2_query/type/integer"
    autoload :Time, "db2_query/type/time"
    autoload :Timestamp, "db2_query/type/timestamp"
    autoload :Date, "db2_query/type/date"
  end

  autoload :SqlStatement, "db2_query/sql_statement"
  autoload :Query, "db2_query/query"
  autoload :Definitions, "db2_query/definitions"
  autoload :DbConnection, "db2_query/db_connection"
  autoload :Result, "db2_query/result"
  autoload :Core, "db2_query/core"
  autoload :Base, "db2_query/base"

  def self.root
    __dir__
  end
end
