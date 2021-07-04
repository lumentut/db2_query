# frozen_string_literal: true

module Db2Query
  module Logger
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
        StatementInvalid.new(message, sql: sql, binds: binds)
      end
    end
  end
end
