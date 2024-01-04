# frozen_string_literal: true

module Db2Query
  module DbConnection
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      mattr_reader :connection
      @@connection = nil

      def new_database_connection
        @@connection = Connection.new(config)
      end
    end
  end

  class Connection
    class Pool < ConnectionPool
      def initialize(config, &block)
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

    attr_reader :config, :connection_pool, :instrumenter, :mutex

    delegate :with, :current_state, :disconnect!, :reload, to: :connection_pool
    delegate :instrument, to: :instrumenter

    include Logger
    include DbStatements

    def initialize(config)
      @config = config
      @instrumenter = ActiveSupport::Notifications.instrumenter
      @mutex = Mutex.new
      @connection_pool = nil
      create_connection_pool
    end

    alias pool with

    def pool_config
      { size: config[:pool], timeout: config[:timeout] }
    end

    def create_connection_pool
      mutex.synchronize do
        return @connection_pool if @connection_pool
        @connection_pool = Pool.new(pool_config) { DbClient.new(config) }
      end
    end
  end
end
