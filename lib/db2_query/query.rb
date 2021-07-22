# frozen_string_literal: true

module Db2Query
  class Query
    attr_reader :columns, :keys, :query_name, :sql, :types

    def initialize(query_name)
      @columns = {}
      @keys = nil
      @query_name = query_name
      @sql = nil
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
      sorted_args = sort_args(args)
      keys.map.with_index do |key, index|
        arg = sorted_args.is_a?(Hash) ? sorted_args[key] : sorted_args[index]
        data_type(key).serialize(arg)
      end
    end

    def column_id
      columns.fetch(:id, nil)
    end

    def column_from_key(key)
      "#{key}".split(".").last.downcase
    end

    def validate_args(args)
      args = args.first.is_a?(Hash) ? args.first : args
      serialized_args(args).tap do |serialized_args|
        given, expected = [args.length, serialized_args.length]
        raise Db2Query::ArgumentError.new(given, expected) unless given == expected
      end
    end

    def validate_result_columns(result_columns)
      res_cols, def_cols = [result_columns.length, length]
      if res_cols != def_cols
        raise Db2Query::ColumnError.new(def_cols, res_cols)
      end
    end

    private
      def new_keys(raw_sql)
        raw_sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "").to_sym }
      end

      def sort_args(args)
        if args.first.is_a?(Hash)
          args[0] = parameters(sql).each_with_object({}) do |key, obj|
            obj[key.to_sym] = args.first[key.to_sym]
          end
        end
        args
      end
  end
end