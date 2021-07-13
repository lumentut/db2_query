# frozen_string_literal: true

module Db2Query
  class Connection < ConnectionPool
    attr_reader :config

    include Logger
    include DbStatements

    def initialize(config, &block)
      @config = config
      super(pool_config, &block)
      @instrumenter = ActiveSupport::Notifications.instrumenter
      @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
    end

    alias pool with

    def pool_config
      { size: config[:pool], timeout: config[:timeout] }
    end

    def current_state
      { size: self.size, available: self.available }
    end

    def reload
      super { |client| client.disconnect! }
    end
  end
end
