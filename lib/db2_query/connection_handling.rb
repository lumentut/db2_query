# frozen_string_literal: true

module DB2Query
  CONNECTION_TYPES = %i[dsn conn_string].freeze

  class ConnectionPool < ActiveRecord::ConnectionAdapters::ConnectionPool
    attr_reader :conn_type

    def initialize(spec)
      @conn_type = (spec.config.keys & DB2Query::CONNECTION_TYPES).first
      super(spec)
    end

    private
      def new_connection
        DB2Query::Connection.new(conn_type, spec.config)
      end
  end

  class ConnectionSpecification #:nodoc:
    attr_reader :name, :config

    def initialize(name, config)
      @name, @config = name, config
    end

    def initialize_dup(original)
      @config = original.config.dup
    end

    def to_hash
      @config.merge(name: @name)
    end

    class Resolver < ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver
      def spec(config)
        pool_name = config if config.is_a?(Symbol)
        spec = resolve(config, pool_name).symbolize_keys
        ConnectionSpecification.new(spec.delete(:name) || "primary", spec)
      end
    end
  end

  class ConnectionHandler < ActiveRecord::ConnectionAdapters::ConnectionHandler
    def establish_connection(config)
      resolver = ConnectionSpecification::Resolver.new(DB2Query::Base.configurations)

      spec = resolver.spec(config)

      remove_connection(spec.name)

      message_bus = ActiveSupport::Notifications.instrumenter
      payload = {
        connection_id: object_id
      }
      if spec
        payload[:spec_name] = spec.name
        payload[:config] = spec.config
      end

      message_bus.instrument("!connection.active_record", payload) do
        owner_to_pool[spec.name] = DB2Query::ConnectionPool.new(spec)
      end

      owner_to_pool[spec.name]
    end
  end

  module ConnectionHandling
    RAILS_ENV   = -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence }
    DEFAULT_ENV = -> { RAILS_ENV.call || "default_env" }

    def lookup_connection_handler(handler_key) # :nodoc:
      handler_key = DB2Query::Base.reading_role
      connection_handlers[handler_key] ||= DB2Query::ConnectionHandler.new
    end

    def resolve_config_for_connection(config_or_env) # :nodoc:
      raise "Anonymous class is not allowed." unless name

      config_or_env ||= DEFAULT_ENV.call.to_sym
      pool_name = primary_class? ? "primary" : name
      self.connection_specification_name = pool_name
      resolver = DB2Query::ConnectionSpecification::Resolver.new(DB2Query::Base.configurations)

      config_hash = resolver.resolve(config_or_env, pool_name).symbolize_keys
      config_hash[:name] = pool_name

      config_hash
    end

    def connection_specification_name
      if !defined?(@connection_specification_name) || @connection_specification_name.nil?
        return self == DB2Query::Base ? "primary" : superclass.connection_specification_name
      end
      @connection_specification_name
    end

    def primary_class?
      self == DB2Query::Base || defined?(Db2Record) && self == Db2Record
    end

    private
      def swap_connection_handler(handler, &blk) # :nodoc:
        old_handler, DB2Query::Base.connection_handler = DB2Query::Base.connection_handler, handler
        return_value = yield
        return_value
      ensure
        DB2Query::Base.connection_handler = old_handler
      end
  end
end
