# frozen_string_literal: true

module Db2Query
  module Core
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      attr_reader :definitions

      delegate :query, :query_rows, :query_value, :query_values, :execute, to: :connection

      def initiation
        yield(self) if block_given?
      end

      def define_query_definitions
        @definitions = new_definitions
      end

      def exec_query_result(query, args)
        reset_id_when_required(query)
        connection.exec_query(query, args)
      end

      def query(query_name, body)
        if body.respond_to?(:call)
          singleton_class.define_method(query_name) do |*args|
            body.call(args << { query_name: query_name })
          end
        elsif body.is_a?(String) && body.strip.length > 0
          query = definitions.lookup(query_name)
          query.define_sql(body.strip)
          singleton_class.define_method(query_name) do |*args|
            exec_query_result(query, args)
          end
        else
          raise Db2Query::QueryMethodError.new
        end
      end
      alias define query

      def fetch(sql, args = [])
        query = query_from_sql_args(sql, args)
        connection.exec_select_query(query, args)
      end

      def fetch_list(sql, args)
        list = args.shift
        fetch(sql_with_list(sql, list), args)
      end

      private
        def new_definitions
          definition_class = "Definitions::#{name}Definitions"
          Object.const_get(definition_class).new(data_types_map)
        rescue Exception => e
          raise Db2Query::Error, e.message
        end

        def reset_id_when_required(query)
          if insert_sql?(query.sql) && !query.column_id.nil?
            table_name = table_name_from_insert_sql(query.sql)
            connection.reset_id_sequence!(table_name)
          end
        end

        def query_name_from_lambda_args(args)
          placeholder = args.pop
          placeholder.fetch(:query_name)
        rescue
          raise Db2Query::ImplementationError.new
        end

        def query_from_sql_args(sql, args)
          query_name = query_name_from_lambda_args(args)
          definitions.lookup(query_name).tap do |query|
            query.define_sql(sql)
          end
        end

        def sql_statement_from_query(method_name)
          sql_query_name = sql_query_symbol(method_name)
          allocate.method(sql_query_name).call
        end

        def define_sql_query(method_name)
          sql_statement = sql_statement_from_query(method_name)
          define(method_name, sql_statement)
        end

        def method_missing(method_name, *args, &block)
          if sql_query_method?(method_name)
            define_sql_query(method_name)
            method(method_name).call(*args)
          elsif method_name == :exec_query
            sql, args = [args.shift, args.first]
            query = query_from_sql_args(sql, args)
            exec_query_result(query, args)
          else
            super
          end
        end
    end
  end
end
