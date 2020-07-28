# frozen_string_literal: true

module DB2Query
  module ConnectionHandling
    RAILS_ENV   = -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence }
    DEFAULT_ENV = -> { RAILS_ENV.call || "default_env" }

    def resolve_config_for_connection(config_or_env) # :nodoc:
      raise "Anonymous class is not allowed." unless name

      config_or_env ||= DEFAULT_ENV.call.to_sym
      pool_name = primary_class? ? "primary" : name
      self.connection_specification_name = pool_name
      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(Base.configurations)

      config_hash = resolver.resolve(config_or_env, pool_name).symbolize_keys
      config_hash[:name] = pool_name

      config_hash
    end

    def connection_specification_name
      if !defined?(@connection_specification_name) || @connection_specification_name.nil?
        return self == Base ? "primary" : superclass.connection_specification_name
      end
      @connection_specification_name
    end

    def primary_class?
      self == Base || defined?(ApplicationRecord) && self == ApplicationRecord
    end
  end
end
