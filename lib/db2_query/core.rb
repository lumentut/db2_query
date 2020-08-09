# frozen_string_literal: true

require "active_record/database_configurations"

module DB2Query
  module Core
    extend ActiveSupport::Concern

    included do
      def self.configurations=(config)
        @@configurations = ActiveRecord::DatabaseConfigurations.new(config)
      end
      self.configurations = {}

      def self.configurations
        @@configurations
      end

      mattr_accessor :connection_handlers, instance_accessor: false, default: {}

      class_attribute :default_connection_handler

      def self.connection_handler
        Thread.current.thread_variable_get("db2q_connection_handler") || default_connection_handler
      end

      def self.connection_handler=(handler)
        Thread.current.thread_variable_set("db2q_connection_handler", handler)
      end

      self.default_connection_handler = DB2Query::ConnectionHandler.new
    end

    module ClassMethods
      def initiation
        yield(self) if block_given?
      end

      def attributes(attr_name, format)
        formatters.store(attr_name, format)
      end

      def query(name, sql_statement)
        if defined_method_name?(name)
          raise ArgumentError, "You tried to define a scope named \"#{name}\" " \
            "on the model \"#{self.name}\", but DB2Query already defined " \
            "a class method with the same name."
        end

        unless sql_statement.strip.match?(/^select/i)
          raise NotImplementedError
        end

        self.class.define_method(name) do |*args|
          connection.exec_query(sql_statement, formatters, args)
        end
      end

      private
        def formatters
          @formatters ||= Hash.new
        end

        def defined_method_name?(name)
          self.class.method_defined?(name) || self.class.private_method_defined?(name)
        end

        def method_missing(method_name, *args, &block)
          sql_methods = self.instance_methods.grep(/_sql/)
          sql_method = "#{method_name}_sql".to_sym

          if sql_methods.include?(sql_method)
            sql_statement = allocate.method(sql_method).call

            unless sql_statement.is_a? String
              raise ArgumentError, "Query methods must return a SQL statement string!"
            end

            query(method_name, sql_statement)

            method(method_name).call(*args)
          else
            super
          end
        end
    end
  end
end
