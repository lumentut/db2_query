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

    def reset_id_sequence(table_name)
      next_val = max_id(table_name) + 1
      execute <<-SQL
        ALTER TABLE #{table_name}
        ALTER COLUMN ID
        RESTART WITH #{next_val}
        SET INCREMENT BY 1
        SET NO CYCLE
        SET CACHE 500
        SET NO ORDER;
      SQL
    end

    private
      def raise_fetch_error
        raise Db2Query::Error, "`fetch`, `fetch_list` and `fetch_extention` methods applied for SQL `select` statement only."
      end

      def max_id(table_name)
        query_value("SELECT COALESCE(MAX (ID),0) FROM #{table_name}")
      end

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
  end
end
