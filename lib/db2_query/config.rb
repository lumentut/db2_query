# frozen_string_literal: true

module Db2Query
  module Config
    extend ActiveSupport::Concern
    DEFAULT_ENV = -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"].presence }

    included do
      @@configurations = nil
    end

    class_methods do
      def configurations
        @@configurations
      end
      alias config configurations

      def load_database_configurations(path = nil)
        file_path = path || "#{Rails.root}/config/db2query.yml"
        if File.exist?(file_path)
          config_file = IO.read(file_path)
          @@configurations = YAML.load(config_file)[DEFAULT_ENV.call].transform_keys(&:to_sym)
        else
          raise Db2Query::Error, "Could not load db2query database configuration. No such file - #{file_path}"
        end
      end
    end
  end
end
