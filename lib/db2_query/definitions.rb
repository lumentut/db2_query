# frozen_string_literal: true

module Db2Query
  class Definitions
    attr_accessor :types, :types_map

    def initialize(types_map)
      @types_map = types_map
      describe
      initialize_types
    end

    def describe
      raise Db2Query::Error, "Please describe query definitions at #{self.class.name}"
    end

    def queries
      @queries ||= {}
    end

    def query_definition(query_name, &block)
      definition = Query.new(query_name)
      yield definition
      queries[query_name] = definition
    end

    def lookup(query_name)
      queries.fetch(query_name)
    rescue
      raise Db2Query::QueryDefinitionError.new(name, query_name)
    end

    private
      def initialize_types
        queries.each do |query_name, definition|
          definition.columns.each do |column, col_def|
            definition.types.store(column, data_type_instance(col_def))
          end
        end
      end

      def data_type_instance(column_definition)
        data_type, options = column_definition
        klass = @types_map.fetch(data_type)
        options.nil? ? klass.new : klass.new(**options)
      rescue
        raise Db2Query::Error, "Not supported `#{data_type}` data type"
      end
  end
end
