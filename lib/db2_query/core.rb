# frozen_string_literal: true

module Db2Query
  class DbClient
    attr_reader :dsn

    delegate :run, :do, to: :client

    def initialize(config)
      @dsn = config[:dsn]
      @idle_time_limit = config[:idle] || 5
      @client = new_db_client
      @last_active = Time.now
    end

    def expire?
      Time.now - @last_active > 60 * @idle_time_limit
    end

    def active?
      @client.connected?
    end

    def connected_and_persist?
      active? && !expire?
    end

    def disconnect!
      @client.drop_all
      @client.disconnect if active?
      @client = nil
    end

    def new_db_client
      ODBC.connect(dsn)
    end

    def client
      return @client if connected_and_persist?
      disconnect!
      @last_active = Time.now
      @client = new_db_client
    end
  end

  module Core
    extend ActiveSupport::Concern
    included do
      @@connection = nil
      @@mutex = Mutex.new
    end

    class_methods do
      def initiation
        yield(self) if block_given?
      end

      def attributes(attr_name, format)
        formatters.store(attr_name, format)
      end

      def connection
        @@connection || create_connection
      end

      def create_connection
        @@mutex.synchronize do
          return @@connection if @@connection
          @@connection = Connection.new(config) { DbClient.new(config) }
        end
      end

      def establish_connection
        load_database_configurations
        create_connection
      end

      def query(name, body)
        if defined_method_name?(name)
          raise Db2Query::Error, "You tried to define a scope named \"#{name}\" " \
            "on the model \"#{self.name}\", but DB2Query already defined " \
            "a class method with the same name."
        end

        if body.respond_to?(:call)
          singleton_class.define_method(name) do |*args|
            body.call(*args)
          end
        elsif body.is_a?(String)
          sql = body.strip
          singleton_class.define_method(name) do |*args|
            connection.exec_query(formatters, sql, args)
          end
        else
          raise Db2Query::Error, "The query body needs to be callable or is a sql string"
        end
      end
      alias define query

      def fetch(sql, args)
        validate_sql(sql)
        connection.exec_query({}, sql, args)
      end

      def fetch_list(sql, args)
        validate_sql(sql)
        raise Db2Query::Error, "Missing @list pointer at SQL" if sql.scan(/\@list+/).length == 0
        raise Db2Query::Error, "The arguments should be an array of list" unless args.is_a?(Array)
        connection.exec_query({}, sql.gsub("@list", "'#{args.join("', '")}'"), [])
      end

      def sql_with_extention(sql, extention)
        validate_sql(sql)
        raise Db2Query::Error, "Missing @extention pointer at SQL" if sql.scan(/\@extention+/).length == 0
        sql.gsub("@extention", extention.strip)
      end

      private
        def formatters
          @formatters ||= Hash.new
        end

        def defined_method_name?(name)
          self.class.method_defined?(name) || self.class.private_method_defined?(name)
        end

        def method_missing(method_name, *args, &block)
          sql_methods = self.instance_methods.grep(/_sql/)
          sql_method = "#{method_name}_sql".to_sym

          if sql_methods.include?(sql_method)
            sql_statement = allocate.method(sql_method).call

            unless sql_statement.is_a? String
              raise Db2Query::Error, "Query methods must return a SQL statement string!"
            end

            query(method_name, sql_statement)

            if args[0].is_a?(Hash)
              keys = sql_statement.scan(/\$\S+/).map { |key| key.gsub!(/[$=]/, "") }
              rearrange_args = {}
              keys.each { |key| rearrange_args[key.to_sym] = args[0][key.to_sym] }
              args[0] = rearrange_args
            end

            method(method_name).call(*args)
          elsif connection.respond_to?(method_name)
            connection.send(method_name, *args)
          else
            super
          end
        end

        def validate_sql(sql)
          raise Db2Query::Error, "SQL have to be in string format" unless sql.is_a?(String)
        end
    end
  end
end
