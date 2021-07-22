# frozen_string_literal: true

require "db2_query/tasks/cli/database_cli"

namespace :db2query do
  desc "Create Database configuration file"
  task :database do
    DatabaseCLI.generate_file
  end
end
