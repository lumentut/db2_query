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

      def query(name, body)
        if body.respond_to?(:call)
          singleton_class.define_method(name) do |*args|
            body.call(args << { query_name: name })
          end
        elsif body.is_a?(String) && body.strip.length > 0
          sql = body.strip
          singleton_class.define_method(name) do |*args|
            binds, args = query_binds(name, sql, args)
            columns, rows = connection.exec_query(sql, binds, args)
            query_result(name, columns, rows)
          end
        else
          raise Db2Query::Error, "The query body needs to be callable or is a sql string"
        end
      end
      alias define query

      def fetch(sql, args)
        name = args.pop()[:query_name]
        binds, args = query_binds(name, sql, args)
        columns, rows = connection.exec_select_query(sql, binds, args)
        query_result(name, columns, rows)
      end

      def fetch_list(sql, args)
        fetch(sql_with_list(sql, args))
      end

      def fetch_extention(sql, extention, args)
        fetch(sql_with_extention(sql, args))
      end

      def sql_with_list(sql, list)
        validate_sql(sql)
        raise Db2Query::Error, "Missing @list pointer at SQL" if sql.scan(/\@list+/).length == 0
        raise Db2Query::Error, "The arguments should be an array of list" unless args.is_a?(Array)
        sql.gsub("@list", "'#{args.join("', '")}'")
      end

      def sql_with_extention(sql, extention)
        validate_sql(sql)
        raise Db2Query::Error, "Missing @extention pointer at SQL" if sql.scan(/\@extention+/).length == 0
        sql.gsub("@extention", extention.strip)
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
            define(method_name, sql_statement)
            args[0] = sort_args(sql_statement, args) if args[0].is_a?(Hash)
            method(method_name).call(*args)
          elsif method_name === "exec_query"
            name = args.pop()[:query_name]
            raise Db2Query::Error, "Method `exec_query` can only be used inside a lambda query" if name.nil?
            binds, args = query_binds(name, sql, args)
            columns, rows = connection.exec_query(sql, binds, args)
            query_result(name, columns, rows)
          else
            super
          end
        end

        def sort_args(sql, args)
          keys = sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "") }
          keys.each_with_object({}) { |key, obj| obj[key.to_sym] = args[0][key.to_sym] }
        end

        def validate_sql(sql)
          raise Db2Query::Error, "SQL have to be in string format" unless sql.is_a?(String)
        end

        class Bind < Struct.new(:name, :value, :index)
        end

        def new_bind(name, key, value)
          Bind.new(key, value, nil)
        end

        def query_binds(query_name, sql, args)
          keys = sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "") }
          sql = sql.tr("$", "")
          args = args[0].is_a?(Hash) ? args[0] : args
          given, expected = args.length, sql.scan(/\?/i).length

          if given != expected
            raise Db2Query::Error, "wrong number of arguments (given #{given}, expected #{expected})"
          end

          if args.is_a?(Hash)
            binds = *args.map { |key, value| new_bind(query_name, key.to_s, value) }
          else
            binds = keys.map.with_index { |key, index| new_bind(query_name, key, args[index]) }
          end

          definition = definitions[query_name]

          args = binds.map do |bind|
            column = bind.name.to_sym
            data_type = definition[column]
            if data_type.nil?
              raise Db2Query::Error, "Column `#{column}` not found at `#{name} query:#{query_name}` Query Definitions."
            end
            data_type.serialize(bind.value)
          end

          [binds.map { |bind| [bind, bind.value] }, args]
        end

        def query_result(name, columns, rows)
          definition = definitions[name]
          rows = rows.each do |row|
            columns.zip(row) do |col, val|
              data_type = definition[col.to_sym]
              data_type.deserialize(val)
            end
          end
          Db2Query::Result.new(columns, rows)
        end
    end
  end
end
