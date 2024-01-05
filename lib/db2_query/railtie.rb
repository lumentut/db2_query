module Db2Query
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/init.rake"
      load "tasks/database.rake"
      load "tasks/initializer.rake"
    end
  end
end
