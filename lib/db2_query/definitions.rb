# frozen_string_literal: true

module Db2Query
  class Definitions
    attr_accessor :types, :types_map
    attr_reader :arguments_map

    def initialize(query_arguments_map, field_types_map)
      @arguments_map = query_arguments_map
      @types_map = field_types_map
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

    def lookup_query(*args)
      query_name, sql = query_definitions(args)
      lookup(query_name).tap do |query|
        query.define_sql(sql)
        query.argument_keys.each do |key|
          key, key_def = query_arg_key(query, key)
          query.argument_types.store(key, data_type_instance(key_def))
        end
      end
    end

    private
      def initialize_types
        queries.each do |query_name, definition|
          definition.columns.each do |column, col_def|
            definition.types.store(column, data_type_instance(col_def))
          end
        end
      end

      def new_data_type(klass, options)
        options.nil? ? klass.new : klass.new(**options)
      rescue Exception => e
        raise Db2Query::Error, e.message
      end

      def data_type_instance(column_definition)
        data_type, options = column_definition
        klass = @types_map.fetch(data_type)
        new_data_type(klass, options)
      rescue
        raise Db2Query::Error, "Not supported `#{data_type}` data type"
      end

      def fetch_query_name(args)
        placeholder = args.pop
        placeholder.fetch(:query_name)
      rescue
        raise Db2Query::ImplementationError.new
      end

      def query_definitions(args)
        case args.first
        when Array
          query_name = fetch_query_name(args.first)
          [query_name, args.last]
        else args
        end
      end

      def query_arg_key(query, key)
        [key, unless arguments_map[query.query_name].nil?
          arguments_map[query.query_name][key]
        else
          query.columns[key]
        end]
      end
  end
end
