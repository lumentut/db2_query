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
          sql = body.strip
          singleton_class.define_method(query_name) do |*args|
            exec_query_result(query_name, sql, args)
          end
        else
          raise Db2Query::Error, "The query body needs to be callable or is a sql string"
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

      def fetch_extention(sql, args)
        extention = args.shift
        fetch(sql_with_extention(sql, extention), args)
      end

      private
        def formatters
          @formatters ||= Hash.new
        end

        def reset_id_when_required(query_name, sql)
          definition = query_definition(query_name)
          if insert_sql?(sql) && !definition[:id].nil?
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
          query_name = args.pop[:query_name]
          if query_name.nil?
            raise Db2Query::Error, "Method `exec_query`, `fetch`, `fetch_list`, and `fetch_extention` can only be implemented inside a lambda query"
          end
          query_name
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

        class Bind < Struct.new(:name, :value, :index)
        end

        def new_bind(name, key, value)
          Bind.new(key, value, nil)
        end

        def query_definition(query_name)
          definition = definitions[query_name]
          if definition.nil?
            raise Db2Query::Error, "No query definition found for #{name}:#{query_name}"
          end
          definition
        end

        def data_type(query_name, column)
          data_type = query_definition(query_name)[column]
          if data_type.nil?
            raise Db2Query::Error, "Column `#{column}` not found at `#{name} query:#{query_name}` Query Definitions."
          end
          data_type
        end

        def query_binds(query_name, sql, args)
          sql, keys, length = bind_variables(sql)
          args = args.first.is_a?(Hash) ? args.first : args
          given, expected = [args.length, length]

          if given != expected
            raise Db2Query::Error, "Wrong number of arguments (given #{given}, expected #{expected})"
          end

          binds = keys.map.with_index do |key, index|
            arg = args.is_a?(Hash) ? args[key.to_sym] : args[index]
            [new_bind(query_name, key, arg), arg]
          end

          args = binds.map do |bind|
            column, value = [bind.first.name.to_sym, bind.first.value]
            data_type(query_name, column).serialize(value)
          end

          [sql, binds, args]
        end

        def validate_columns(query_name, columns)
          definition = definitions[query_name]
          res_cols, def_cols = [columns.length, definition.length]
          if res_cols != def_cols
            raise Db2Query::Error, "Wrong number of columns (query definitions #{def_cols}, query result #{res_cols})"
          end
        end

        def serialized_rows(query_name, columns, rows)
          rows.each do |row|
            columns.zip(row) do |col, val|
              data_type(query_name, col.to_sym).deserialize(val)
            end
          end
        end

        def query_result(query_name, columns, rows)
          validate_columns(query_name, columns)
          rows = serialized_rows(query_name, columns, rows)
          Db2Query::Result.new(columns, rows)
        end
    end
  end
end
