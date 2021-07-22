# frozen_string_literal: true

require_relative "base_cli"

class InitializerCLI < BaseCLI
  source_root File.expand_path("../templates", __FILE__)

  def create_database_config
    template "initializer.rb", File.join("config/initializers/db2query.rb")
  end
end
