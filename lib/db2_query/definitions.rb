# frozen_string_literal: true

module Db2Query
  class Definitions
    attr_accessor :types, :types_map

    class QueryDefinition
      attr_reader :columns, :query_name, :types

      def initialize(query_name)
        @query_name = query_name
        @types = {}
        @columns = {}
      end

      def map_column(name, args)
        @columns[name] = args
      end

      def method_missing(method_name, *args, &block)
        map_column(method_name, args)
      end

      def data_type(key)
        column = "#{key}".split(".").last.downcase
        types.fetch(column.to_sym)
      rescue
        raise Db2Query::Error, "No column #{column} found at query: #{query_name} definitions"
      end

      def length
        columns.length
      end
    end

    def initialize(types_map)
      @types_map = types_map
      describe
    end

    def describe
      raise Db2Query::Error, "Please describe query definitions at #{self.class.name}"
    end

    def initialize_types
      queries.each do |query_name, definition|
        definition.columns.each do |column, col_def|
          definition.types.store(column, data_type_instance(col_def))
        end
      end
    end

    def queries
      @queries ||= {}
    end

    def query_definition(query_name, &block)
      definition = QueryDefinition.new(query_name)
      yield definition
      queries[query_name] = definition
    end

    def lookup(query_name)
      queries.fetch(query_name)
    rescue
      raise Db2Query::QueryDefinitionError.new(name, query_name)
    end

    private
      def data_type_instance(column_definition)
        data_type, options = column_definition
        klass = @types_map.fetch(data_type)
        options.nil? ? klass.new : klass.new(**options)
      rescue
        raise Db2Query::Error, "Not supported `#{data_type}` data type"
      end
  end
end
