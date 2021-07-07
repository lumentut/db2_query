# frozen_string_literal: true

module Db2Query
  module DbStatements
    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def query(sql)
        pool do |odbc_conn|
          stmt = odbc_conn.run(sql)
          stmt.to_a
        ensure
          stmt.drop unless stmt.nil?
        end
      end

      def query_rows(sql)
        query(sql)
      end

      def query_value(sql)
        rows = query(sql)
        row = rows.first
        row && row.first
      end

      def query_values(sql)
        query(sql).map(&:first)
      end

      def execute(sql, args = [])
        pool do |odbc_conn|
          odbc_conn.do(sql, *args)
        end
      end

      def exec_query(formatters, sql, args = [])
        binds, args = extract_binds_from_sql(sql, args)
        log(sql, "SQL", binds, args) do
          run_query(formatters, db2_spec_sql(sql), binds, args)
        end
      end

      def run_query(formatters, sql,  binds, args = [])
        pool do |odbc_conn|
          begin
            if args.empty?
              stmt = odbc_conn.run(sql)
            else
              stmt = odbc_conn.run(sql, *args)
            end
            columns = stmt.columns.values.map { |col| col.name.downcase }
            rows = stmt.to_a
          ensure
            stmt.drop unless stmt.nil?
          end
          Db2Query::Result.new(columns, rows, formatters)
        end
      end

      private
        def iud_sql?(sql)
          sql.match?(/insert into|update|delete/i)
        end

        def iud_ref_table(sql)
          sql.match?(/delete/i) ? "OLD TABLE" : "NEW TABLE"
        end

        def db2_spec_sql(sql)
          if iud_sql?(sql)
            "SELECT * FROM #{iud_ref_table(sql)} (#{sql})"
          else
            sql
          end.tr("$", "")
        end

        def extract_binds_from_sql(sql, args)
          keys = sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "") }
          sql = sql.tr("$", "")
          args = args[0].is_a?(Hash) ? args[0] : args
          given, expected = args.length, sql.scan(/\?/i).length

          if given != expected
            raise Db2Query::Error, "wrong number of arguments (given #{given}, expected #{expected})"
          end

          if args.is_a?(Hash)
            binds = *args.map do |key, value|
              Db2Query::Bind.new(key.to_s, value, nil)
            end
          else
            binds = keys.map.with_index do |key, index|
              Db2Query::Bind.new(key, args[index], nil)
            end
          end

          [binds.map { |bind| [bind, bind.value] }, binds.map { |bind| bind.value }]
        end
    end
  end
end
