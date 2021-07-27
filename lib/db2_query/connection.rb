# frozen_string_literal: true

module Db2Query
  class Connection
    class ConnectionPool < ::ConnectionPool
      def initialize(config, &block)
        @config = config
        super(config, &block)
      end

      def current_state
        { size: self.size, available: self.available }
      end

      def disconnect!
        shutdown { |client| client.disconnect! }
      end

      def reload
        super { |client| client.disconnect! }
      end
    end

    attr_reader :config, :connection_pool, :mutex

    delegate :with, :current_state, :disconnect!, :reload, to: :connection_pool

    include Logger
    include DbStatements

    def initialize(config)
      @config = config
      @instrumenter = ActiveSupport::Notifications.instrumenter
      @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
      @mutex = Mutex.new
      create_connection_pool
    end

    alias pool with

    def pool_config
      { size: config[:pool], timeout: config[:timeout] }
    end

    def create_connection_pool
      mutex.synchronize do
        return @connection_pool if @connection_pool
        @connection_pool = ConnectionPool.new(pool_config) { DbClient.new(config) }
      end
    end
  end
end
