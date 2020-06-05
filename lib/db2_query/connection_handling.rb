# frozen_string_literal: true

module Db2Query
  module ConnectionHandling
    extend ActiveSupport::Concern

    DEFAULT_DB = "primary"

    included do |base|
      def base.inherited(child)
        child.connection = @connection
      end

      base.extend ClassMethods
      base.connection = nil
    end

    module ClassMethods
      attr_reader :connection

      def connection=(connection)
        @connection = connection
        update_descendants_connection unless self.descendants.empty?
      end

      def update_descendants_connection
        self.descendants.each { |child| child.connection = @connection }
      end

      def establish_connection(db_name = nil)
        clear_connection unless self.connection.nil?
        db_name = db_name.nil? ? DEFAULT_DB : db_name.to_s

        self.load_database_configurations if self.configurations.nil?

        if self.configurations[db_name].nil?
          raise Error, "Database (:#{db_name}) not found at database configurations."
        end

        conn_type, conn_config = extract_configuration(db_name)

        connector = ODBCConnector.new(conn_type, conn_config)
        self.connection = Connection.new(connector, db_name)
      end

      def current_database
        @connection.db_name
      end

      def clear_connection
        @connection.disconnect!
        @connection = nil
      end
    end
  end
end
