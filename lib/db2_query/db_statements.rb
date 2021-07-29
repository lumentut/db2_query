# frozen_string_literal: true

module Db2Query
  module DbStatements
    def query(sql)
      pool do |client|
        stmt = client.run(sql)
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
      pool do |client|
        client.do(sql, *args)
      end
    end

    def exec_query(query, args = [])
      sql, binds, args = query.exec_query_arguments(args)
      log(sql, binds, args) do
        pool do |client|
          stmt = client.run(sql, *args)
          columns = stmt.columns.values.map { |col| col.name.downcase }
          rows = stmt.to_a
          Db2Query::Result.new(columns, rows, query)
        ensure
          stmt.drop unless stmt.nil?
        end
      end
    end

    def reset_id_sequence!(table_name)
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
      def max_id(table_name)
        query_value("SELECT COALESCE(MAX (ID),0) FROM #{table_name}")
      end
  end
end
