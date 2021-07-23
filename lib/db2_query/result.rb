# frozen_string_literal: true

module Db2Query
  class Result < ActiveRecord::Result
    attr_reader :definition

    def initialize(columns, rows, definition)
      @definition = definition
      super(columns, rows, {})
    end
  
    alias query definition

    def record
      return nil if rows.empty?
      @record ||= new_record(rows.first)
    end

    def records
      @records ||= rows.map { |row| new_record(row) }
    end

    def length
      records.length
    end

    def to_h
      rows.map do |row|
        index, hash = [0, {}]
        while index < columns.length
          attr_name = columns[index].to_sym
          hash[attr_name] = query.data_type(attr_name).deserialize(row[index])
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
      def initialize(row, columns, definition)
        index = 0
        while index < columns.length
          col, val = [columns[index], row[index]]
          add_attribute(col, val, definition)
          index += 1
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

      private
        def add_attribute(attr_name, value, definition)
          class_eval { attr_accessor "#{attr_name}" }
          data_type = definition.data_type(attr_name)
          send("#{attr_name}=", data_type.deserialize(value))
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
