# frozen_string_literal: true

module Db2Query
  class Base
    include DatabaseConfigurations
    include ConnectionHandling

    class << self
      include SQLValidator

      def attributes(attr_name, format)
        attr_format.store(attr_name, format)
      end

      def query(method_name, sql_statement)
        unless is_query?(sql_statement)
          raise Error, "Query only for SQL query commands."
        end

        if self.class.respond_to?(method_name)
          raise Error, "Query :#{method_name} has been defined before"
        end

        self.class.define_method(method_name) do |*args|
          log(sql_statement, args) do
            columns, rows = connection.exec_query(sql_statement, *args)
            Result.new(self, method_name, columns, rows, attr_format)
          end
        end
      end

      private
        def attr_format
          @attr_format ||= Hash.new
        end

        def define_query_method(method_name, sql_statement)
          if is_query?(sql_statement)
            query(method_name, sql_statement)
          else
            raise NotImplementedError
          end
        end

        def method_missing(method_name, *args, &block)
          sql_methods = self.instance_methods.grep(/_sql/)
          sql_method = "#{method_name}_sql".to_sym

          if sql_methods.include?(sql_method)
            sql_statement = allocate.method(sql_method).call

            raise Error, "Query methods must return a SQL statement string!" unless sql_statement.is_a? String

            expected_args = sql_statement.count "?"
            given_args = args.size

            if expected_args == given_args
              define_query_method(method_name, sql_statement)
            else
              raise ArgumentError, "wrong number of arguments (given #{given_args}, expected #{expected_args})"
            end

            method(method_name).call(*args)
          else
            super
          end
        end

        def instrumenter
          @instrumenter ||= ActiveSupport::Notifications.instrumenter
        end

        def log(sql_statement, args)
          instrumenter.instrument(
            "sql.db2_query",
            sql:   sql_statement,
            name:  self,
            binds: args) do
            yield
          end
        end
    end
  end
end
