# frozen_string_literal: true

require "db2_query/tasks"

namespace :db2query do
  desc "Create Database configuration file"
  task :database do
    Db2Query::DatabaseTask.generate_file
  end
end
