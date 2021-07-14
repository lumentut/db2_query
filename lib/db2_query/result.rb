# frozen_string_literal: true

module Db2Query
  class Result < ActiveRecord::Result
    def initialize(columns, rows)
      super(columns, rows, {})
    end

    def includes_column?(name)
      @columns.include? name
    end

    def record
      return nil if rows.empty?
      @record ||= Record.new(rows[0], columns)
    end

    def records
      @records ||= rows.map do |row|
        Record.new(row, columns)
      end
    end

    def to_h
      rows.map do |row|
        columns.zip(row).each_with_object({}) { |cr, h| h[cr[0].to_sym] = cr[1] }
      end
    end

    def method_missing(method_name, *args, &block)
      if record.respond_to?(method_name)
        record.send(method_name)
      else
        super
      end
    end

    def inspect
      entries = records.take(11).map!(&:inspect)
      entries[10] = "..." if entries.size == 11
      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    class Record
      def initialize(row, columns)
        columns.zip(row) do |col, val|
          class_eval { attr_accessor "#{col}" }
          send("#{col}=", val)
        end
      end

      def inspect
        inspection = if defined?(instance_variables) && instance_variables
          instance_variables.map do |attribute|
            "#{attribute[1..-1]}: #{instance_variable_get(attribute)}"
          end.compact.join(", ")
        else
          "not initialized"
        end
        "#<Record #{inspection}>"
      end
    end
  end
end
