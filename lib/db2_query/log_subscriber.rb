# frozen_string_literal: true

module Db2Query
  class LogSubscriber < ActiveSupport::LogSubscriber
    # Embed in a String to clear all previous ANSI sequences.
    CLEAR   = "\e[0m"
    BOLD    = "\e[1m"

    # Colors
    BLACK   = "\e[30m"
    RED     = "\e[31m"
    GREEN   = "\e[32m"
    YELLOW  = "\e[33m"
    BLUE    = "\e[34m"
    MAGENTA = "\e[35m"
    CYAN    = "\e[36m"
    WHITE   = "\e[37m"

    def sql(event)
      class_load_duration = color("#{event.payload[:name]} Load (#{event.duration.round(2)}ms)", :cyan, true)
      sql_statement = color("#{event.payload[:sql]}", :blue, true)
      message = "  #{class_load_duration} #{sql_statement}"

      if event.payload[:binds].size > 0
        binds = color("#{event.payload[:binds]}", :white)
        message = "#{message} [#{binds}]"
      end

      puts message
    end

    def schema_task(event)
      puts color("  Done (#{(event.duration).round(2)}ms)", :green, true)
    end

    def schema_task_perform(event)
      task_name = color(":#{event.payload[:task_name]}", :white, true)
      schema = color("#{event.payload[:schema]}", :white, true)
      puts "- Performing #{task_name} in #{schema} ..."
    end

    private
      def color(text, color, bold = false) # :doc:
        return text unless colorize_logging
        color = self.class.const_get(color.upcase) if color.is_a?(Symbol)
        bold  = bold ? BOLD : ""
        "#{bold}#{color}#{text}#{CLEAR}"
      end
  end
end
