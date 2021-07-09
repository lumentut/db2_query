# frozen_string_literal: true

require "active_record"
require "active_support"
require "active_support/concurrency/load_interlock_aware_monitor"
require "connection_pool"
require "odbc_utf8"

module Db2Query
  extend ActiveSupport::Autoload

  autoload :Version
  autoload :Error
  autoload :Config
  autoload :Logger
  autoload :DbClient
  autoload :DbStatements
  autoload :ConnectionHandler
  autoload :Connection
  autoload :Result
  autoload :Core
  autoload :Base

  def self.root
    __dir__
  end

  require "db2_query/railtie" if defined?(Rails)
end
