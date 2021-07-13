# frozen_string_literal: true

module Db2Query
  module DbStatements
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

    def exec_select_query(sql, binds = [], args = [])
      raise_fetch_error if iud_sql?(sql)
      log(sql, "SQL", binds, args) do
        run_query(sql, args)
      end
    end

    def exec_query(sql, binds = [], args = [])
      log(sql, "SQL", binds, args) do
        run_query(sql, args)
      end
    end

    def run_query(sql, args = [])
      sql = db2_spec_sql(sql)
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
        [columns, rows]
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

      def raise_fetch_error
        raise Db2Query::Error, "`fetch` and `fetch_list` method only for SQL `select` statement."
      end
  end
end
