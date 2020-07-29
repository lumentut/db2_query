# frozen_string_literal: true

require 'db2_query'
require 'rails'

module DB2Query
  class Railtie < Rails::Railtie
    railtie_name :db2_query

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/*.rake").each { |f| load f }
    end

    initializer "db2_query.database_initialization" do
      DB2Query::Base.configurations = DB2Query.config
      DB2Query::Base.establish_connection :primary
    end
  end
end
