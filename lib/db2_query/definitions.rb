
# frozen_string_literal: true

module Db2Query
  class Definitions
    attr_accessor :types

    class DataTypes
      attr_accessor :columns

      def initialize
        @columns = {}
      end

      def map_column(name, args)
        @columns[name] = args
      end

      def method_missing(method_name, *args, &block)
        map_column(method_name, args)
      end
    end

    def initialize(types_map)
      describe
      @types = {}
      initialize_types(types_map)
    end

    alias query_definitions types

    def describe
      raise Db2Query::Error, "No Query Definitions found"
    end

    def initialize_types(types_map)
      queries.each do |query, definitions|
        types[query] = definitions.each_with_object({}) do |data, hash|
          col, definition = data
          data_type, options = definition
          klass = types_map[data_type]
          if klass.nil?
            raise Db2Query::Error, "No column `#{col}` data types found in `query :#{query}` Query Definitions"
          end
          hash[col] = options.nil? ? klass.new : klass.new(**options)
        end
      end
    end

    def queries
      @queries ||= {}
    end

    def column_types(query_name, &block)
      data_types = DataTypes.new
      yield data_types
      queries[query_name] = data_types.columns
    end
  end
end
