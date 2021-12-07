# frozen_string_literal: true

module Db2Query
  class Query
    attr_reader :query_name, :sql, :columns, :keys, :types, :argument_types

    include SqlStatement

    def initialize(query_name = nil)
      @columns = {}
      @query_name = query_name
      @sql_statement = nil
      @argument_types = {}
      @types = {}
    end

    def define_sql(sql)
      @keys ||= sql_arguments(sql)
      @sql ||= sql.tr("$", "")
    end

    def map_column(name, args)
      @columns[name] = args
    end

    def method_missing(method_name, *args, &block)
      map_column(method_name, args)
    end

    def data_type(key)
      column = column_from_key(key)
      types.fetch(column.to_sym)
    rescue
      raise Db2Query::Error, "No column #{column} found at query: #{query_name} definitions"
    end

    def argument_type(key)
      argument_types.fetch(key) || data_type(key)
    rescue
      raise Db2Query::Error, "No argument #{key} type found at query: #{query_name}"
    end

    def argument_keys
      keys.map do |key|
        arg_key = "#{key}".split(".").last
        arg_key.to_sym unless arg_key.nil?  
      end
    end

    def length
      columns.length
    end

    def raw_query_args(args)
      case args
      when Array, Hash
        validated_args(args)
      else
        args
      end
    end

    def define_args(args)
      class_eval { attr_accessor "args" }
      send("args=", raw_query_args(args))
    end

    def sorted_args(args)
      argument_keys.map.with_index do |key, index|
        serialized_arg(args.is_a?(Hash) ? args[key] : args[index], key)
      end
    end

    def column_id
      columns.fetch(:id, nil)
    end

    def validate_result_columns(result_columns)
      res_cols, def_cols = [result_columns.length, length]
      if res_cols != def_cols
        raise Db2Query::ColumnError.new(def_cols, res_cols)
      end
    end

    def exec_query_arguments(args)
      [db2_spec_sql, binds(args), validated_args(args)]
    end

    def validate_select_query
      if iud_sql?
        raise Db2Query::Error, "Fetch queries are used for select statement query only."
      end
    end

    class Bind < Struct.new(:name, :value)
    end

    private
      def sql_arguments(raw_sql)
        raw_sql.scan(/\$\S+/).map { |arg| arg.gsub!(/[$=,)]/, "").to_sym }
      end

      def serialized_arg(arg, key)
        query_name.nil? ? arg : argument_type(key).serialize(arg)
      end

      def column_from_key(key)
        "#{key}".split(".").last.downcase
      end

      def new_bind(key, arg)
        [Bind.new(column_from_key(key), arg), arg]
      end

      def binds(args)
        keys.map.with_index do |key, index|
          new_bind(key, args.first.is_a?(Hash)? args.first[key] : args[index])
        end
      end

      def validated_args(args)
        arguments = args.first.is_a?(Hash) ? args.first : args
        given, expected = [arguments.length, keys.length]
        raise Db2Query::ArgumentError.new(given, expected) unless given == expected
        sorted_args(arguments)
      end
  end
end
