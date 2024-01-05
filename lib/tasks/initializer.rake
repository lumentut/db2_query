# frozen_string_literal: true

require "db2_query/tasks"

namespace :db2query do
  desc "Create Initializer file"
  task :initializer do
    Db2Query::InitializerTask.generate_file
  end
end