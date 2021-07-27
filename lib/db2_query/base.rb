# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include Helper
    include Quoting
    include FieldType
    include Core

    mattr_reader :connection
    @@connection = nil

    def self.inherited(subclass)
      subclass.define_query_definitions
    end

    def self.establish_connection
      load_database_configurations
      @@connection = Connection.new(config)
    end
  end
end
