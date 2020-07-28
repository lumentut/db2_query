# frozen_string_literal: true

require "odbc_utf8"
require "db2_query/odbc_connector"
require "db2_query/database_statements"

module ActiveRecord
  module ConnectionHandling
    def db2_query_connection(config)
      conn_type = (config.keys & DB2Query::CONNECTION_TYPES).first
      if conn_type.nil?
        raise ArgumentError, "No data source name (:dsn) or connection string (:conn_str) provided."
      end
      connector = DB2Query::ODBCConnector.new(conn_type, config)
      ConnectionAdapters::DB2QueryConnection.new(connector, config)
    end
  end

  module ConnectionAdapters
    class DB2QueryConnection
      include DB2Query::DatabaseStatements
      include ActiveSupport::Callbacks
      define_callbacks :checkout, :checkin

      set_callback :checkin, :after, :enable_lazy_transactions!

      attr_accessor :pool
      attr_reader :owner, :connector, :lock
      alias :in_use? :owner

      def initialize(connector, config)
        @connector = connector
        @instrumenter  = ActiveSupport::Notifications.instrumenter
        @config = config
        @pool = ActiveRecord::ConnectionAdapters::NullPool.new
        @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
        connect
      end

      def connect
        @connection = connector.connect
        @connection.use_time = true
      end

      def active?
        @connection.connected?
      end

      def reconnect!
        disconnect!
        connect
      end
      alias reset! reconnect!

      def disconnect!
        if @connection.connected?
          @connection.commit
          @connection.disconnect
        end
      end

      def check_version
      end

      def enable_lazy_transactions!
        @lazy_transactions_enabled = true
      end

      def lease
        if in_use?
          msg = +"Cannot lease connection, "
          if @owner == Thread.current
            msg << "it is already leased by the current thread."
          else
            msg << "it is already in use by a different thread: #{@owner}. " \
                   "Current thread: #{Thread.current}."
          end
          raise ActiveRecordError, msg
        end

        @owner = Thread.current
      end

      def verify!
        reconnect! unless active?
      end

      def translate_exception_class(e, sql, binds)
        message = "#{e.class.name}: #{e.message}"

        exception = translate_exception(
          e, message: message, sql: sql, binds: binds
        )
        exception.set_backtrace e.backtrace
        exception
      end

      def log(sql, name = "SQL", binds = [], type_casted_binds = [], statement_name = nil) # :doc:
        @instrumenter.instrument(
          "sql.active_record",
          sql:               sql,
          name:              name,
          binds:             binds,
          type_casted_binds: type_casted_binds,
          statement_name:    statement_name,
          connection_id:     object_id,
          connection:        self) do
          @lock.synchronize do
            yield
          end
        rescue => e
          raise translate_exception_class(e, sql, binds)
        end
      end

      def translate_exception(exception, message:, sql:, binds:)
        case exception
        when RuntimeError
          exception
        else
          ActiveRecord::StatementInvalid.new(message, sql: sql, binds: binds)
        end
      end

      def expire
        if in_use?
          if @owner != Thread.current
            raise ActiveRecordError, "Cannot expire connection, " \
              "it is owned by a different thread: #{@owner}. " \
              "Current thread: #{Thread.current}."
          end

          @idle_since = Concurrent.monotonic_time
          @owner = nil
        else
          raise ActiveRecordError, "Cannot expire connection, it is not currently leased."
        end
      end

      def steal!
        if in_use?
          if @owner != Thread.current
            pool.send :remove_connection_from_thread_cache, self, @owner

            @owner = Thread.current
          end
        else
          raise ActiveRecordError, "Cannot steal connection, it is not currently leased."
        end
      end

      def seconds_idle # :nodoc:
        return 0 if in_use?
        Concurrent.monotonic_time - @idle_since
      end

      private
        def type_map
          @type_map ||= Type::TypeMap.new.tap do |mapping|
            initialize_type_map(mapping)
          end
        end

        def alias_type(map, new_type, old_type)
          map.register_type(new_type) do |_, *args|
            map.lookup(old_type, *args)
          end
        end

        def initialize_type_map(map)
          map.register_type "boolean",              Type::Boolean.new
          map.register_type ODBC::SQL_CHAR,         Type::String.new
          map.register_type ODBC::SQL_LONGVARCHAR,  Type::Text.new
          map.register_type ODBC::SQL_TINYINT,      Type::Integer.new(limit: 4)
          map.register_type ODBC::SQL_SMALLINT,     Type::Integer.new(limit: 8)
          map.register_type ODBC::SQL_INTEGER,      Type::Integer.new(limit: 16)
          map.register_type ODBC::SQL_BIGINT,       Type::BigInteger.new(limit: 32)
          map.register_type ODBC::SQL_REAL,         Type::Float.new(limit: 24)
          map.register_type ODBC::SQL_FLOAT,        Type::Float.new
          map.register_type ODBC::SQL_DOUBLE,       Type::Float.new(limit: 53)
          map.register_type ODBC::SQL_DECIMAL,      Type::Float.new
          map.register_type ODBC::SQL_NUMERIC,      Type::Integer.new
          map.register_type ODBC::SQL_BINARY,       Type::Binary.new
          map.register_type ODBC::SQL_DATE,         Type::Date.new
          map.register_type ODBC::SQL_DATETIME,     Type::DateTime.new
          map.register_type ODBC::SQL_TIME,         Type::Time.new
          map.register_type ODBC::SQL_TIMESTAMP,    Type::DateTime.new
          map.register_type ODBC::SQL_GUID,         Type::String.new

          alias_type map, ODBC::SQL_BIT,            "boolean"
          alias_type map, ODBC::SQL_VARCHAR,        ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WCHAR,          ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WVARCHAR,       ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WLONGVARCHAR,   ODBC::SQL_LONGVARCHAR
          alias_type map, ODBC::SQL_VARBINARY,      ODBC::SQL_BINARY
          alias_type map, ODBC::SQL_LONGVARBINARY,  ODBC::SQL_BINARY
          alias_type map, ODBC::SQL_TYPE_DATE,      ODBC::SQL_DATE
          alias_type map, ODBC::SQL_TYPE_TIME,      ODBC::SQL_TIME
          alias_type map, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP
        end
    end
  end
end
