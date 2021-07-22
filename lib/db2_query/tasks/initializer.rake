# frozen_string_literal: true

require "db2_query/tasks/cli/initializer_cli"

namespace :db2query do
  desc "Create Initializer file"
  task :initializer do
    InitializerCLI.generate_file
  end
end
