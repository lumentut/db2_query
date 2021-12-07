# frozen_string_literal: true

module Db2Query
  module Helper
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def sql_with_list(sql, list)
        if sql.scan(/\@list+/).length == 0
          raise Db2Query::MissingListError, "Missing @list pointer at SQL"
        elsif !list.is_a?(Array)
          raise Db2Query::ListTypeError, "The arguments should be an array of list"
        end
        sql.gsub("@list", "'#{list.join("', '")}'")
      end

      def sql_with_extension(sql, extension)
        if sql.scan(/\@extension+/).length == 0
          raise Db2Query::ExtensionError, "Missing @extension pointer at SQL"
        end
        sql.gsub("@extension", extension.strip)
      end
      alias sql_with_extention sql_with_extension

      private
        def sql_query_methods
          self.instance_methods.grep(/_sql/)
        end

        def sql_query_symbol(method_name)
          "#{method_name}_sql".to_sym
        end

        def sql_query_method?(method_name)
          sql_query_name = sql_query_symbol(method_name)
          sql_query_methods.include?(sql_query_name)
        end

        def validate_sql(sql)
          raise Db2Query::Error, "SQL have to be in string format" unless sql.is_a?(String)
        end

        def fetch_error_message
          "`fetch`, `fetch_list` and `fetch_extension` methods applied for SQL `select` statement only."
        end
    end
  end
end
