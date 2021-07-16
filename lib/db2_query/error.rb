# frozen_string_literal: true

module Db2Query
  class Error < StandardError
  end

  class ArgumentError < StandardError
    def initialize(given, expected)
      @given = given
      @expected = expected
      super(message)
    end

    def message
      "Wrong number of arguments (given #{@given}, expected #{@expected})"
    end
  end

  class ColumnError < StandardError
    def initialize(def_cols, res_cols)
      @def_cols = def_cols
      @res_cols = res_cols
      super(message)
    end

    def message
      "Wrong number of columns (query definitions #{@def_cols}, query result #{@res_cols})"
    end
  end

  class ConnectionError < StandardError
    def initialize(odbc_message)
      @odbc_message = odbc_message
      super(message)
    end

    def message
      "Unable to activate ODBC DSN connection #{@odbc_message}"
    end
  end

  class ExtentionError < StandardError
    def message
      "Missing @extention pointer at SQL"
    end
  end

  class ImplementationError < StandardError
    def message
      "Method `fetch`, `fetch_list`, and `exec_query` can only be implemented inside a lambda query"
    end
  end

  class ListTypeError < StandardError
    def message
      "The arguments should be an array of list"
    end
  end

  class MissingListError < StandardError
    def message
      "Missing @list pointer at SQL"
    end
  end

  class QueryDefinitionError < StandardError
    def initialize(klass, query_name, column = nil)
      @klass = klass
      @query_name = query_name
      @column = column
      super(message)
    end

    def message
      unless column.nil?
        "Column `#{@column}` not found at `#{@klass} query:#{@query_name}` Query Definitions."
      else
        "No query definition found for #{@klass}:#{@query_name}"
      end
    end
  end

  class QueryMethodError < StandardError
    def message
      "The query body needs to be callable or is a SQL statement string"
    end
  end
end
