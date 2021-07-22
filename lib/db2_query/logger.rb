# frozen_string_literal: true

module Db2Query
  module Logger
    class Bind < Struct.new(:name, :value)
    end

    def translate_exception_class(e, sql, binds)
      message = "#{e.class.name}: #{e.message}"

      exception = translate_exception(
        e, message: message, sql: sql, binds: binds
      )
      exception.set_backtrace e.backtrace
      exception
    end

    def logger_binds(query, args)
      query.keys.map.with_index do |key, index|
        arg = args.is_a?(Hash) ? args[key] : args[index]
        [Bind.new(query.column_from_key(key), arg), arg]
      end
    end

    def log(query, args = [], &block)
      binds = logger_binds(query, args)
      @instrumenter.instrument(
        "sql.active_record",
        sql:               query.sql,
        name:              "SQL",
        binds:             binds,
        type_casted_binds: args,
        statement_name:    nil,
        connection_id:     object_id,
        connection:        self) do
        @lock.synchronize do
          yield
        end
      rescue => e
        raise translate_exception_class(e, query.sql, binds)
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

    class StatementInvalid < ActiveRecord::ActiveRecordError
      def initialize(message = nil, sql: nil, binds: nil)
        super(message || $!.try(:message))
        @sql = sql
        @binds = binds
      end

      attr_reader :sql, :binds
    end
  end
end
