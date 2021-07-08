# frozen_string_literal: true

require "db2_query"
require "rails"

module Db2Query
  class Railtie < ::Rails::Railtie
    railtie_name :db2_query

    rake_tasks do
      db2_query_path = File.expand_path(__dir__)
      Dir.glob("#{db2_query_path}/tasks/*.rake").each { |f| load f }
    end

    config.app_generators do
			require "#{File.expand_path('..', __dir__)}/rails/query_generator.rb"
		end
  end
end
