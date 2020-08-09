# frozen_string_literal: true

module DB2Query
  class << self
    def config
      @config ||= read_config
    end

    def config_path
      if defined?(Rails)
        "#{Rails.root}/config/db2query_database.yml"
      else
        ENV["DQ_CONFIG_PATH"]
      end
    end

    def config_file
      Pathname.new(config_path)
    end

    def read_config
      erb = ERB.new(config_file.read)
      YAML.parse(erb.result(binding)).transform.transform_keys(&:to_sym)
    end

    def connection_env
      ENV["RAILS_ENV"].to_sym
    end
  end
end
