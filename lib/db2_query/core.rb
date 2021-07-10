# frozen_string_literal: true

module Db2Query
  module Core
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def initiation
        yield(self) if block_given?
      end

      def attributes(attr_name, format)
        formatters.store(attr_name, format)
      end

      def query(name, body)
        if body.respond_to?(:call)
          singleton_class.define_method(name) do |*args|
            body.call(*args)
          end
        elsif body.is_a?(String)
          sql = body.strip
          singleton_class.define_method(name) do |*args|
            connection.exec_query(formatters, sql, args)
          end
        else
          raise Db2Query::Error, "The query body needs to be callable or is a sql string"
        end
      end
      alias define query

      def fetch(sql, args)
        validate_sql(sql)
        connection.exec_query({}, sql, args)
      end

      def fetch_list(sql, args)
        validate_sql(sql)
        raise Db2Query::Error, "Missing @list pointer at SQL" if sql.scan(/\@list+/).length == 0
        raise Db2Query::Error, "The arguments should be an array of list" unless args.is_a?(Array)
        connection.exec_query({}, sql.gsub("@list", "'#{args.join("', '")}'"), [])
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
          elsif connection.respond_to?(method_name)
            connection.send(method_name, *args)
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
    end
  end
end
