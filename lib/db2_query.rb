# frozen_string_literal:true

require "yaml"
require "erb"
require "active_record"
require "active_support"
require "db2_query/config"
require "db2_query/error"
require "db2_query/connection_handling"

module DB2Query
  extend ActiveSupport::Autoload

  autoload :Version
  autoload :Base
  autoload :Bind
  autoload :Core
  autoload :DatabaseStatements
  autoload :Connection
  autoload :ODBCConnector
  autoload :Formatter
  autoload :Result

  require "db2_query/railtie" if defined?(Rails)
end
