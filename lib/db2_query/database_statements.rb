# frozen_string_literal: true

module Db2Query
  module DatabaseStatements
    def query_value(sql) # :nodoc:
      single_value_from_rows(query(sql))
    end

    def query(sql)
      exec_query(sql).last
    end

    def query_values(sql)
      query(sql).map(&:first)
    end

    def current_database
      db_name.to_s
    end

    def current_schema
      query_value("select current_schema from sysibm.sysdummy1").strip
    end
    alias library current_schema

    private
      def single_value_from_rows(rows)
        row = rows.first
        row && row.first
      end
  end
end
