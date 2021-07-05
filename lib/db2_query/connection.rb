# frozen_string_literal: true

module Db2Query
  class Bind < Struct.new(:name, :value, :index)
  end

  class Connection < ConnectionPool
    attr_reader :config

    include Logger

    def initialize(config, &block)
      @config = config
      super(pool_config, &block)
      @instrumenter = ActiveSupport::Notifications.instrumenter
      @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
    end

    alias pool with

    def pool_config
      { size: config[:pool], timeout: config[:timeout] }
    end

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
      single_value_from_rows(query(sql))
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
      sql = db2_spec_sql(sql)
      log(sql, "SQL", binds, args) do
        run_query(formatters, sql, binds, args)
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
      def single_value_from_rows(rows)
        row = rows.first
        row && row.first
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

      def extract_binds_from_sql(sql, args)
        keys = sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=]/, "") }
        sql = sql.tr("$", "")
        args = args[0].is_a?(Hash) ? args[0] : args
        given, expected = args.length, sql.scan(/\?/i).length

        if given != expected
          raise Db2Query::Error, "wrong number of arguments (given #{given}, expected #{expected})"
        end

        if args.is_a?(Hash)
          binds = *args.map do |key, value|
            if args[key.to_sym].nil?
              raise Db2Query::Error, "Column name: `#{key}` not found inside sql statement."
            end
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
