# frozen_String_literal: true

module DB2Query
  class Connection
    ADAPTER_NAME = "DB2Query"

    include DB2Query::DatabaseStatements
    include ActiveSupport::Callbacks

    define_callbacks :checkout, :checkin

    set_callback :checkin, :after, :enable_lazy_transactions!

    attr_accessor :pool
    attr_reader :owner, :connector, :lock
    alias :in_use? :owner

    def initialize(type, config)
      @connector = DB2Query::ODBCConnector.new(type, config)
      @instrumenter  = ActiveSupport::Notifications.instrumenter
      @config = config
      @pool = ActiveRecord::ConnectionAdapters::NullPool.new
      @lock = ActiveSupport::Concurrency::LoadInterlockAwareMonitor.new
      connect
    end

    def adapter_name
      self.class::ADAPTER_NAME
    end

    def current_transaction
    end

    def begin_transaction(options = {})
    end

    def transaction_open?
    end

    def requires_reloading?
      false
    end

    def close
      pool.checkin self
    end

    def connect
      @connection = connector.connect
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
        raise DB2Query::Error, msg
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
        DB2Query::StatementInvalid.new(message, sql: sql, binds: binds)
      end
    end

    def expire
      if in_use?
        if @owner != Thread.current
          raise DB2Query::Error, "Cannot expire connection, " \
            "it is owned by a different thread: #{@owner}. " \
            "Current thread: #{Thread.current}."
        end

        @idle_since = Concurrent.monotonic_time
        @owner = nil
      else
        raise DB2Query::Error, "Cannot expire connection, it is not currently leased."
      end
    end

    def steal!
      if in_use?
        if @owner != Thread.current
          pool.send :remove_connection_from_thread_cache, self, @owner

          @owner = Thread.current
        end
      else
        raise DB2Query::Error, "Cannot steal connection, it is not currently leased."
      end
    end

    def seconds_idle
      return 0 if in_use?
      Concurrent.monotonic_time - @idle_since
    end
  end
end
