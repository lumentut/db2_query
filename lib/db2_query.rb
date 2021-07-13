# frozen_string_literal: true

require "active_record"
require "active_support"
require "active_support/concurrency/load_interlock_aware_monitor"
require "active_model/type"
require "connection_pool"
require "odbc_utf8"

module Db2Query
  autoload :Version, "db2_query/version"
  autoload :Error, "db2_query/error"
  autoload :Config, "db2_query/config"
  autoload :Logger, "db2_query/logger"
  autoload :DbClient, "db2_query/db_client"
  autoload :DbStatements, "db2_query/db_statements"

  module Type
    autoload :Binary, "db2_query/type/binary"
    autoload :Boolean, "db2_query/type/boolean"
    autoload :Decimal, "db2_query/type/decimal"
    autoload :String, "db2_query/type/string"
    autoload :Text, "db2_query/type/text"
  end

  autoload :Definitions, "db2_query/definitions"
  autoload :ColumnDefinitions, "db2_query/column_definitions"
  autoload :ConnectionHandler, "db2_query/connection_handler"
  autoload :Connection, "db2_query/connection"
  autoload :Result, "db2_query/result"
  autoload :Core, "db2_query/core"
  autoload :Base, "db2_query/base"

  def self.root
    __dir__
  end

  require "db2_query/railtie" if defined?(Rails)
end
