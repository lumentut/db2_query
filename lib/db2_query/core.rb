# frozen_string_literal: true

module Db2Query
  module Core
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      delegate :query, :query_rows, :query_value, :query_values, :execute, to: :connection

      def initiation
        yield(self) if block_given?
      end

      def exec_query_result(query_name, sql, args)
        sql, binds, args = query_binds(query_name, sql, args)
        reset_id_when_required(query_name, sql)
        columns, rows = connection.exec_query(sql, binds, args)
        query_result(query_name, columns, rows)
      end

      def query(query_name, body)
        if body.respond_to?(:call)
          singleton_class.define_method(query_name) do |*args|
            body.call(args << { query_name: query_name })
          end
        elsif body.is_a?(String) && body.strip.length > 0
          singleton_class.define_method(query_name) do |*args|
            exec_query_result(query_name, body.strip, args)
          end
        else
          raise Db2Query::QueryMethodError.new
        end
      end
      alias define query

      def fetch(sql, args = [])
        query_name = query_name_from_lambda_args(args)
        sql, binds, args = query_binds(query_name, sql, args)
        columns, rows = connection.exec_select_query(sql, binds, args)
        query_result(query_name, columns, rows)
      end

      def fetch_list(sql, args)
        list = args.shift
        fetch(sql_with_list(sql, list), args)
      end

      private
        def formatters
          @formatters ||= Hash.new
        end

        def reset_id_when_required(query_name, sql)
          column_id = definitions.lookup(query_name).columns.fetch(:id, nil)
          if insert_sql?(sql) && !column_id.nil?
            table_name = table_name_from_insert_sql(sql)
            connection.reset_id_sequence!(table_name)
          end
        end

        def sql_statement_from_query(method_name, args)
          sql_query_name = sql_query_symbol(method_name)
          sql_statement = allocate.method(sql_query_name).call
          args = sorted_args(sql_statement, args)
          [sql_statement, args]
        end

        def query_name_from_lambda_args(args)
          placeholder = args.pop
          placeholder.fetch(:query_name)
        rescue
          raise Db2Query::ImplementationError.new
        end

        def method_missing(method_name, *args, &block)
          if sql_method?(method_name)
            sql_statement, args = sql_statement_from_query(method_name, args)
            define(method_name, sql_statement)
            method(method_name).call(*args)
          elsif method_name == :exec_query
            sql, args = [args.shift, args.first]
            query_name = query_name_from_lambda_args(args)
            exec_query_result(query_name, sql, args)
          else
            super
          end
        end

        def sorted_args(sql, args)
          if args.first.is_a?(Hash)
            args[0] = parameters(sql).each_with_object({}) do |key, obj|
              obj[key.to_sym] = args.first[key.to_sym]
            end
          end
          args
        end

        class Bind < Struct.new(:name, :value)
        end

        def serialized_bind(type, column, value)
          value = type.serialize(value)
          [Bind.new(column, value), value]
        end

        def query_binds(query_name, sql, args)
          sql, keys, length = bind_variables(sql)
          args = args.first.is_a?(Hash) ? args.first : args
          given, expected = [args.length, length]

          raise Db2Query::ArgumentError.new(given, expected) unless given == expected

          definition = definitions.lookup(query_name)

          binds = keys.map.with_index do |key, index|
            arg = args.is_a?(Hash) ? args[key] : args[index]
            data_type = definition.data_type(key)
            serialized_bind(data_type, key.to_s, arg)
          end

          args = binds.map { |bind| bind.first.value }
          [sql, binds, args]
        end

        def validate_columns(columns, definition)
          res_cols, def_cols = [columns.length, definition.length]
          if res_cols != def_cols
            raise Db2Query::ColumnError.new(def_cols, res_cols)
          end
        end

        def query_result(query_name, columns, rows)
          definition = definitions.lookup(query_name)
          validate_columns(columns, definition)
          Db2Query::Result.new(columns, rows, definition)
        end
    end
  end
end
