# frozen_string_literal: true

module DB2Query
  class Result < ActiveRecord::Result
    attr_reader :formatters

    def initialize(columns, rows, formatters = {}, column_types = {})
      @formatters = formatters
      super(columns, rows, column_types)
    end

    def records
      @records ||= rows.map do |row|
        Record.new(row, columns, formatters)
      end
    end

    def inspect
      entries = records.take(11).map!(&:inspect)

      entries[10] = "..." if entries.size == 11

      "#<#{self.class.name} @records=[#{entries.join(', ')}]>"
    end

    class Record
      attr_reader :formatters

      def initialize(row, columns, formatters)
        @formatters = formatters
        columns.zip(row) do |col, val|
          column, value = format(col, val)
          singleton_class.class_eval { attr_accessor "#{column}" }
          send("#{column}=", value)
        end
      end

      def inspect
        inspection = if defined?(instance_variables) && instance_variables
          instance_variables.reject { |var| var == :@formatters }.map do |attr|
            value = instance_variable_get(attr)
            "#{attr[1..-1]}: #{(value.kind_of? String) ? %Q{"#{value}"} : value}"
          end.compact.join(", ")
        else
          "not initialized"
        end

        "#<Record #{inspection}>"
      end

      private
        def format(col, val)
          column = col.downcase
          format_name = formatters[column.to_sym]
          unless format_name.nil?
            formatter = DB2Query::Formatter.lookup(format_name)
            val = formatter.format(val)
          end
          [column, val]
        end
    end
  end
end
