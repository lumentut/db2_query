# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include ConnectionHandler
    include QueryDefinitions
    include Helper
    include Quoting
    include Core

    def self.inherited(subclass)
      subclass.definitions.initialize_types
    end
  end
end
