# frozen_string_literal: true

module Db2Query
  module SQLValidator
    DEFAULT_TASK_COMMANDS = [:create, :drop, :delete, :insert, :set, :update]
    COMMENT_REGEX = %r{/\*(?:[^\*]|\*[^/])*\*/}m

    def task_command?(sql_statement)
      sql_statement.match?(task_commands_regexp)
    end

    def query_command?(sql_statement)
      sql_statement.match?(/select/i)
    end

    def is_query?(sql_statement)
      query_command?(sql_statement) && !task_command?(sql_statement)
    end

    private
      def task_commands_regexp
        parts = DEFAULT_TASK_COMMANDS.map { |part| /#{part}/i }
        /\A(?:[\(\s]|#{COMMENT_REGEX})*#{Regexp.union(*parts)}/i
      end
  end
end
