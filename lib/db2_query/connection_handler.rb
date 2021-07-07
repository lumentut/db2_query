# frozen_string_literal: true

module Db2Query
  module ConnectionHandler
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      mattr_accessor :mutex
      @@mutex = Mutex.new

      @@connection = nil

      def connection
        @@connection || create_connection
      end

      def create_connection
        mutex.synchronize do
          return @@connection if @@connection
          @@connection = Connection.new(config) { DbClient.new(config) }
        end
      end

      def establish_connection
        load_database_configurations
        create_connection
      end
    end
  end
end
