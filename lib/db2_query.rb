# frozen_string_literal: true

require "active_record"
require "active_support"
require "active_support/concurrency/load_interlock_aware_monitor"
require "connection_pool"
require "odbc_utf8"

module Db2Query
  extend ActiveSupport::Autoload

  autoload :Version
  autoload :Config
  autoload :Connection
  autoload :Core
  autoload :Result
  autoload :Logger
  autoload :Error
  autoload :Base

  require "db2_query/railtie" if defined?(Rails)
end
