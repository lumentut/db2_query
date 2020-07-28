# frozen_string_literal: true

module DB2Query
  class Result < ActiveRecord::Result

    def initialize(columns, rows, column_types = {})
      super(columns, rows, column_types)
    end

    def records
      @records ||= rows.map do |row|
        Record.new(row, columns)
      end
    end

    def inspect
      entries = records.take(11).map!(&:inspect)

      entries[10] = "..." if entries.size == 11

      "#<#{self.class.name} @records=[#{entries.join(', ')}]>"
    end

    class Record
      def initialize(row, columns)
        columns.zip(row) do |column, val|
          singleton_class.class_eval { attr_accessor "#{column.downcase}" }
          send("#{column.downcase}=", val)
        end
      end

      def inspect
        inspection = if defined?(instance_variables) && instance_variables
          instance_variables.collect do |attr|
            value = instance_variable_get(attr)
            "#{attr[1..-1]}: #{(value.kind_of? String) ? %Q{"#{value}"} : value}"
          end.compact.join(", ")
        else
          "not initialized"
        end

        "#<Record #{inspection}>"
      end
    end
  end
end
