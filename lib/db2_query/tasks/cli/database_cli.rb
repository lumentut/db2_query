# frozen_string_literal: true

require_relative "base_cli"

class DatabaseCLI < BaseCLI
  source_root File.expand_path("../templates", __FILE__)

  def create_database_config
    template "database.rb", File.join("config/db2query.yml")
  end
end
