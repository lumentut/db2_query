# frozen_string_literal: true

module Db2Query
  class Result < ActiveRecord::Result
    attr_reader :definition

    alias query definition

    delegate :data_type, :validate_result_columns, to: :definition

    def initialize(columns, rows, definition)
      @definition = definition
      validate_result_columns(columns)
      super(columns, rows, {})
    end

    def record
      records.first
    end

    def records
      @records ||= rows.map { |row| new_record(row) }
    end

    def to_h
      rows.map do |row|
        index, hash = [0, {}]
        while index < columns.length
          attr_name = columns[index].to_sym
          hash[attr_name] = data_type(attr_name).deserialize(row[index])
          index += 1
        end
        hash
      end
    end

    def inspect
      entries = records.take(11).map!(&:inspect)
      entries[10] = "..." if entries.size == 11
      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    class Record
      attr_reader :definition

      delegate :data_type, to: :definition

      def initialize(row, columns, definition)
        @definition = definition
        add_attributes(columns, row)
      end

      def inspect
        inspection = if defined?(instance_variables) && instance_variables
          instance_variables.reject { |var| var == :@definition }.map do |attribute|
            "#{attribute[1..-1]}: #{instance_variable_get(attribute)}"
          end.compact.join(", ")
        else
          "not initialized"
        end
        "#<Record #{inspection}>"
      end

      private
        def add_attributes(columns, row)
          index = 0
          while index < columns.length
            column, value = [columns[index], row[index]]
            class_eval { attr_accessor "#{column}" }
            send("#{column}=", data_type(column).deserialize(value))
            index += 1
          end
        end
    end

    private
      def new_record(row)
        Record.new(row, columns, definition)
      end

      def method_missing(method_name, *args, &block)
        if record.respond_to?(method_name)
          record.send(method_name)
        else
          super
        end
      end
  end
end
