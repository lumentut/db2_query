# frozen_string_literal: true

namespace :db2query do
  desc "Create Initializer and Database configuration file"
  task :init do
    Rake::Task["db2query:database"].invoke
    Rake::Task["db2query:initializer"].invoke
  end
end
