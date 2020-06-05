# frozen_string_literal: true

module Db2Query
  class Schema
    include SQLValidator

    attr_accessor :config, :current_schema

    def initialize
      @config = Config.new
    end

    def connection
      Base.connection
    end

    def schema
      config.schema
    end

    def sql_files_dir(path)
      config.sql_files_dir = path
    end

    def is_valid_schema?
      connection.current_schema == config.schema
    end

    def perform_tasks(&block)
      raise Error, "#{config.main_library} is not connection's current schema" unless is_valid_schema?

      if Base.connection.nil? && config.init_connection
        Base.establish_connection
      end

      puts "\n# Perform Schema Tasks: \n\n"

      instance_eval(&block)

      puts "\n"
    end

    def sql(sql_statement)
      raise Error, "Task only for SQL execute commands." if query_command?(sql_statement)
      sql_statement
    end

    def file(file_name)
      sql(File.read("#{config.sql_files_dir}/#{file_name}"))
    end

    def task(task_name, sql = nil, *args)
      Task.new(schema, task_name).perform do
        if block_given?
          yield(sql)
        else
          execute(sql, *args)
        end
      end
    end

    def execute(sql, *args)
      connection.execute(sql, *args)
    rescue ::ODBC::Error => e
      raise Error, "Unable to execute SQL - #{e}"
    end

    def tables_in_schema
      connection.query_values <<-SQL
        SELECT table_name FROM SYSIBM.SQLTABLES
        WHERE table_schem='#{schema}' AND table_type='TABLE'
      SQL
    end

    def self.initiation(&block)
      new.initiation(&block)
    end

    def initiation(&block)
      instance_eval(&block)
    end

    class Task
      attr_reader :instrumenter, :schema, :task_name, :start_time, :finish_time

      def initialize(schema, task_name)
        @schema = schema
        @task_name = task_name
        @instrumenter = ActiveSupport::Notifications.instrumenter
      end

      def perform
        instrumenter.instrument("schema_task_perform.db2_query", payload)
        instrumenter.start("schema_task.db2_query", payload)
        yield
        instrumenter.finish("schema_task.db2_query", payload)
      end

      private
        def payload
          { task_name: task_name, schema: schema }
        end
    end

    class Config
      attr_accessor :initial_tasks, :init_connection, :schema, :sql_files_dir

      def initialize
        @init_connection = false
      end
    end
  end
end
