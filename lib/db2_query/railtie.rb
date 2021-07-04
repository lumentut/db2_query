# frozen_string_literal: true

require "db2_query"
require "rails"

module Db2Query
  class Railtie < ::Rails::Railtie
    railtie_name :db2_query

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/*.rake").each { |f| load f }
    end
  end
end
