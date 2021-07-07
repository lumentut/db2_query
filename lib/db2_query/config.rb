# frozen_string_literal: true

module Db2Query
  module Config
    DEFAULT_ENV = -> { (Rails.env if defined?(Rails.env)) || ENV["RAILS_ENV"].presence }

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      mattr_accessor :configurations
      @@configurations = nil

      alias config configurations

      def default_path
        "#{Rails.root}/config/db2query.yml"
      end

      def load_database_configurations(path = nil)
        config_file = IO.read(path || default_path)
        @@configurations = YAML.load(config_file)[DEFAULT_ENV.call].transform_keys(&:to_sym)
      rescue Exception => e
        raise Db2Query::Error, e.message
      end
    end
  end
end
