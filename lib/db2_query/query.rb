# frozen_string_literal: true

module Db2Query
  class Query
    attr_reader :columns, :keys, :query_name, :sql, :types

    include SqlStatement

    def initialize(query_name)
      @columns = {}
      @query_name = query_name
      @sql_statement = nil
      @types = {}
    end

    def define_sql(sql)
      @keys ||= new_keys(sql)
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

    def length
      columns.length
    end

    def serialized_args(args)
      keys.map.with_index do |key, index|
        arg = args.is_a?(Hash) ? args[key] : args[index]
        data_type(key).serialize(arg)
      end
    end

    def column_id
      columns.fetch(:id, nil)
    end

    def column_from_key(key)
      "#{key}".split(".").last.downcase
    end

    def validate_result_columns(result_columns)
      res_cols, def_cols = [result_columns.length, length]
      if res_cols != def_cols
        raise Db2Query::ColumnError.new(def_cols, res_cols)
      end
    end

    def exec_query_arguments(args)
      [db2_spec_sql, binds(args), validate_args(args)]
    end

    def validate_select_query
      if iud_sql?
        raise Db2Query::Error, "Fetch queries are used for select statement query only."
      end
    end

    class Bind < Struct.new(:name, :value)
    end

    private
      def new_keys(raw_sql)
        raw_sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "").to_sym }
      end

      def binds(args)
        keys.map.with_index do |key, index|
          arg = args.first.is_a?(Hash) ? args.first[key] : args.first[index]
          [Bind.new(column_from_key(key), arg), arg]
        end
      end

      def validate_args(args)
        args = args.first.is_a?(Hash) ? args.first : args
        serialized_args(args).tap do |serialized_args|
          given, expected = [args.length, serialized_args.length]
          raise Db2Query::ArgumentError.new(given, expected) unless given == expected
        end
      end
  end
end
