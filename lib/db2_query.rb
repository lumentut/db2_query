# frozen_string_literal:true

require "yaml"
require "erb"
require "active_record"
require "active_support"
require "active_record/database_configurations"
require "db2_query/config"

module DB2Query
  extend ActiveSupport::Autoload

  autoload :Version
  autoload :Base
  autoload :Core
  autoload :ConnectionHandling
  autoload :DatabaseStatements
  autoload :ODBCConnector
  autoload :Result
end
