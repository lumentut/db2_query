# frozen_string_literal: true

module DB2Query
  class Error < StandardError
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
