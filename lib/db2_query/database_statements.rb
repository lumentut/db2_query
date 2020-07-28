# frozen_String_literal: true

module DB2Query
  module DatabaseStatements
    def query(sql)
      stmt = @connection.run(sql)
      stmt.to_a
    ensure
      stmt.drop unless stmt.nil?
    end

    def query_rows(sql)
      query(sql)
    end

    def query_value(sql, name = nil)
      single_value_from_rows(query(sql))
    end

    def query_values(sql, name = nil)
      query(sql).map(&:first)
    end

    def execute(sql, args = [])
      if args.empty?
        @connection.do(sql)
      else
        @connection.do(sql, *args)
      end
    end

    def exec_query(sql, args = [], name = "SQL")
      binds, args = extract_binds_from_sql(sql, args)
      log(sql, name, binds, args) do
        begin
          if args.empty?
            stmt = @connection.run(sql)
          else
            stmt = @connection.run(sql, *args)
          end
          columns = stmt.columns.values.map { |col| col.name.downcase }
          rows = stmt.to_a
        ensure
          stmt.drop unless stmt.nil?
        end
        DB2Query::Result.new(columns, rows)
      end
    end

    private
      def key_finder_regex(k)
        /#{k} =\\? | #{k}=\\? | #{k}= \\? /i
      end

      def extract_binds_from_sql(sql, args)
        question_mark_positions = sql.enum_for(:scan, /\?/i).map { Regexp.last_match.begin(0) }
        args = args.first.is_a?(Hash) ? args.first : args.is_a?(Array) ? args : [args]
        given, expected = args.length, question_mark_positions.length

        if given != expected
          raise ArgumentError, "wrong number of arguments (given #{given}, expected #{expected})"
        end

        if args.is_a?(Hash)
          binds = args.map do |key, value|
            position = sql.enum_for(:scan, key_finder_regex(key)).map { Regexp.last_match.begin(0) }
            if position.empty?
              raise ArgumentError, "Column name: `#{key}` not found inside sql statement."
            elsif position.length > 1
              raise ArgumentError, "Can't handle such this kind of sql. Please refactor your sql."
            else
              index = position[0]
            end

            OpenStruct.new({ name: key.to_s, value: value, index: index })
          end
          binds = binds.sort_by { |bind| bind.index }
          [binds.map { |bind| [bind, bind.value] }, binds.map { |bind| bind.value}]
        elsif question_mark_positions.length == 1 && args.length == 1
          column = sql[/(.*?) = \?|(.*?) =\?|(.*?)= \?|(.*?)=\?/m, 1].split.last.downcase
          bind = Bind.new(column, args)
          OpenStruct.new({ name: column, value: args})
          [[[bind, bind.value]], bind.value]
        else
          [args.map { |arg| [nil, arg] }, args]
        end
      end
  end
end
