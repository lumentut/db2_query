# frozen_string_literal: true

module Db2Query
  class Railtie < ::Rails::Railtie
    railtie_name :db2_query

    rake_tasks do
      tasks_path = "#{File.expand_path("..", __dir__)}/tasks"
      Dir.glob("#{tasks_path}/*.rake").each { |file| load file }
    end

    initializer "db2_query.database_initialization" do
      Path.database_config_file = "#{Rails.root}/config/db2query_database.yml"
      Base.load_database_configurations
      Base.establish_connection
    end

    initializer "db2_query.attach_log_subscription" do
      LogSubscriber.attach_to :db2_query
    end
  end
end
