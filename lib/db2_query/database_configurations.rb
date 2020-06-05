# frozen_string_literal: true

module Db2Query
  module DatabaseConfigurations
    extend ActiveSupport::Concern

    DEFAULT_ENV = -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence }

    included do |base|
      @@configurations = Hash.new

      base.extend ClassMethods
    end

    module ClassMethods
      def configurations
        @@configurations
      end

      def load_database_configurations(path = nil)
        file_path = path.nil? ? Path.database_config_file : path

        if File.exist?(file_path)
          file = File.read(file_path)
          @@configurations = YAML.load(ERB.new(file).result)[DEFAULT_ENV.call]
        else
          raise Error, "Could not load db2query database configuration. No such file - #{file_path}"
        end
      end

      def configurations_databases
        self.load_database_configurations if self.configurations.nil?
        @@configurations.keys
      end

      private
        def extract_configuration(db_name)
          configs = @@configurations[db_name.to_s]
          conn_config = configs.nil? ? configs : configs.transform_keys(&:to_sym)
          conn_type = (conn_config.keys & ODBCConnector::CONNECTION_TYPES).first

          if conn_type.nil?
            raise Error, "No data source name (:dsn) or connection string (:conn_str) provided."
          end

          [conn_type, conn_config]
        end
    end
  end
end
