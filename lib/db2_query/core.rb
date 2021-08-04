# frozen_string_literal: true

module Db2Query
  module Core
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      attr_reader :definitions

      delegate :query_rows, :query_value, :query_values, :execute, to: :connection

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

      def query_resolver(query_name, body)
        if body.is_a?(Proc)
          -> args { body.call(args << { query_name: query_name }) }
        elsif body.is_a?(String)
          definition = definitions.lookup_query(query_name, body.strip)
          -> args { exec_query_result(definition, args) }
        else
          raise Db2Query::QueryMethodError.new
        end
      end

      def query(*query_args)
        if query_args.first.is_a?(Symbol)
          query_name, body = query_args
          resolver = query_resolver(query_name, body)
          singleton_class.define_method(query_name) { |*args| resolver.call(args) }
        elsif query_args.first.is_a?(String)
          sql, args = [query_args.first.strip, query_args.drop(1)]
          definition = raw_query(sql, args)
          connection.raw_query(definition.db2_spec_sql, definition.args)
        end
      end
      alias define query

      def fetch(sql, args = [])
        query = definitions.lookup_query(args, sql)
        query.validate_select_query
        connection.exec_query(query, args)
      end

      def fetch_list(sql, args)
        list = args.first
        fetch(sql_with_list(sql, list), args.drop(1))
      end

      private
        def new_definitions
          definition_class = "Definitions::#{name}Definitions"
          Object.const_get(definition_class).new(field_types_map)
        rescue Exception => e
          raise Db2Query::Error, e.message
        end

        def reset_id_when_required(query)
          if query.insert_sql? && !query.column_id.nil?
            connection.reset_id_sequence!(query.table_name)
          end
        end

        def raw_query(sql, args)
          Query.new.tap do |query|
            query.define_sql(sql)
            query.define_args(args)
          end
        end

        def define_sql_query(method_name)
          sql_query_name = sql_query_symbol(method_name)
          sql_statement = allocate.method(sql_query_name).call
          define(method_name, sql_statement)
        end

        def method_missing(method_name, *args, &block)
          if sql_query_method?(method_name)
            define_sql_query(method_name)
            method(method_name).call(*args)
          elsif method_name == :exec_query
            sql, args = [args.shift, args.first]
            query = definitions.lookup_query(args, sql)
            exec_query_result(query, args)
          else
            super
          end
        end
    end
  end
end
