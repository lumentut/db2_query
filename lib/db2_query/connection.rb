# frozen_string_literal: true

module Db2Query
  class Connection
    include DatabaseStatements

    attr_reader :connector, :db_name, :odbc_conn

    def initialize(connector, db_name)
      @connector = connector
      @db_name = db_name.to_sym
      connect
    end

    def connect
      @odbc_conn = connector.connect
      @odbc_conn.use_time = true
    end

    def active?
      @odbc_conn.connected?
    end

    def disconnect!
      @odbc_conn.drop_all
      @odbc_conn.disconnect if active?
    end

    def reconnect!
      disconnect!
      connect
    end
    alias reset! reconnect!

    def execute(sql, *args)
      reset! unless active?
      @odbc_conn.do(sql, *args)
    end

    def exec_query(sql, *args)
      reset! unless active?
      statement = @odbc_conn.run(sql, *args)
      columns = statement.columns.values
      rows = statement.to_a
      [columns, rows]
    ensure
      statement.drop if statement
    end
  end
end
