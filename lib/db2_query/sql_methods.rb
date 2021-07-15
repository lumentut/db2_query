# frozen_string_literal: true

module Db2Query
  module SqlMethods
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      private
        def trim_sql(sql)
          sql.tr("$", "")
        end

        def insert_sql?(sql)
          sql.match?(/insert/i)
        end

        def table_name_from_insert_sql(sql)
          sql.split("INTO ").last.split(" ").first
        end

        def sql_methods
          self.instance_methods.grep(/_sql/)
        end

        def sql_query_symbol(method_name)
          "#{method_name}_sql".to_sym
        end

        def sql_method?(method_name)
          sql_query_name = sql_query_symbol(method_name)
          sql_methods.include?(sql_query_name)
        end

        def parameters(sql)
          sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "") }
        end

        def placeholder_length(sql)
          sql.scan(/\?/i).length
        end

        def bind_variables(sql)
          [trim_sql(sql), parameters(sql), placeholder_length(sql)]
        end

        def reset_id_when_required(query_name, sql)
          definition = query_definition(query_name)
          if insert_sql?(sql) && !definition[:id].nil?
            table_name = table_name_from_insert_sql(sql)
            reset_id_sequence(table_name)
          end
        end

        def max_id(table_name)
          query_value("SELECT COALESCE(MAX (ID),0) FROM #{table_name}")
        end

        def reset_id_sequence(table_name)
          next_val = max_id(table_name) + 1
          connection.execute <<-SQL
            ALTER TABLE #{table_name}
            ALTER COLUMN ID
            RESTART WITH #{next_val}
            SET INCREMENT BY 1
            SET NO CYCLE
            SET CACHE 500
            SET NO ORDER;
          SQL
        end
    end
  end
end
