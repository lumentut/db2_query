# frozen_string_literal:true

require "odbc"
require "yaml"
require "erb"
require "active_record"
require "active_support"

module Db2Query
  extend ActiveSupport::Autoload

  autoload :Version
  autoload :Error
  autoload :Path
  autoload :Schema
  autoload :DatabaseConfigurations
  autoload :ODBCConnector
  autoload :Connection
  autoload :ConnectionHandling
  autoload :DatabaseStatements
  autoload :SQLValidator
  autoload :LogSubscriber
  autoload :Formatter
  autoload :Column
  autoload :Result
  autoload :Base
end

require "db2_query/railtie"
