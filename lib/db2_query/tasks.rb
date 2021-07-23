# frozen_string_literal: true

require "thor"

module Db2Query
  class Tasks < Thor::Group
    include Thor::Actions

    class << self
      alias generate_file start
    end
  end

  class DatabaseTask < Tasks
    source_root File.expand_path("../tasks/templates", __FILE__)

    def create_database_config_file
      template "database.rb", File.join("config/db2query.yml")
    end
  end

  class InitializerTask < Tasks
    source_root File.expand_path("../tasks/templates", __FILE__)

    def create_initializer_file
      template "initializer.rb", File.join("config/initializers/db2query.rb")
    end
  end
end
