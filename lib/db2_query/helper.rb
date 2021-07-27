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

      def sql_with_extention(sql, extention)
        if sql.scan(/\@extention+/).length == 0
          raise Db2Query::ExtentionError, "Missing @extention pointer at SQL"
        end
        sql.gsub("@extention", extention.strip)
      end

      private
        def insert_sql?(sql)
          sql.match?(/insert/i)
        end

        def table_name_from_insert_sql(sql)
          sql.split("INTO ").last.split(" ").first
        end

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

        def placeholder_length(sql)
          sql.scan(/\?/i).length
        end

        def validate_sql(sql)
          raise Db2Query::Error, "SQL have to be in string format" unless sql.is_a?(String)
        end

        def fetch_error_message
          "`fetch`, `fetch_list` and `fetch_extention` methods applied for SQL `select` statement only."
        end
    end
  end
end
