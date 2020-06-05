# frozen_string_literal: true

module Db2Query
  class Result
    attr_reader :core, :klass, :rows, :columns, :column_metadatas, :attr_format

    def initialize(core, klass, columns, rows, attr_format = {})
      @core = core
      @klass = klass.to_s.camelize
      @rows  = rows
      @attr_format = attr_format
      @columns = []
      @column_metadatas = extract_metadatas(columns)
    end

    def to_a
      core.const_set(klass, row_class) unless core.const_defined?(klass)

      rows.map do |row|
        (core.const_get klass).new(row, column_metadatas)
      end
    end

    def to_hash
      rows.map do |row|
        Hash[columns.zip(row)]
      end
    end

    def pluck(*column_names)
      records.map do |record|
        column_names.map { |column_name| record.send(column_name) }
      end
    end

    def first
      records.first
    end

    def last
      records.last
    end

    def size
      records.size
    end
    alias length size

    def each(&block)
      records.each(&block)
    end

    def inspect
      entries = records.take(11).map!(&:inspect)
      entries[10] = "..." if entries.size == 11
      "#<#{self.class} [#{entries.join(', ')}]>"
    end

    private
      def records
        @records ||= to_a
      end

      def extract_metadatas(columns)
        columns.map do |col|
          @columns << column_name = col.name.downcase
          Column.new(column_name, col.type, attr_format[column_name.to_sym])
        end
      end

      def row_class
        Class.new do
          def initialize(row, columns_metadata)
            columns_metadata.zip(row) do |column, val|
              self.class.send(:attr_accessor, column.name.to_sym)
              instance_variable_set("@#{column.name}", column.format(val))
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

            "#<#{self.class} #{inspection}>"
          end
        end
      end
  end
end
