# frozen_string_literal: true

module Db2Query
  class Column
    attr_reader :name, :type, :formatter

    FLOAT_TYPES = [ODBC::SQL_FLOAT, ODBC::SQL_DOUBLE, ODBC::SQL_DECIMAL, ODBC::SQL_REAL]
    INTEGER_TYPES = [ODBC::SQL_TINYINT, ODBC::SQL_SMALLINT, ODBC::SQL_INTEGER, ODBC::SQL_BIGINT, ODBC::SQL_NUMERIC]

    def initialize(name, type, format = nil)
      @name = name
      @type = type.to_i

      @formatter = if custom_format?(format)
        Formatter.lookup(format)
      elsif float_type?
        FloatFormatter.new
      elsif integer_type?
        IntegerFormatter.new
      else
        BareFormatter.new
      end
    end

    def format(value)
      formatter.format(value)
    end

    private
      def custom_format?(format)
        Formatter.registry.key?(format)
      end

      def float_type?
        FLOAT_TYPES.include?(type)
      end

      def integer_type?
        INTEGER_TYPES.include?(type)
      end
  end
end
