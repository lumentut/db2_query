# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include Helper
    include DbConnection
    include FieldType
    include Core

    def self.inherited(subclass)
      subclass.define_query_definitions
    end

    def self.establish_connection
      load_database_configurations
      new_database_connection
    end
  end
end
