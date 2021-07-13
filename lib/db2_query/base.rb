# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include ConnectionHandler
    include QueryDefinitions
    include Core

    def self.inherited(subclass)
      subclass.set_definitions
    end
  end
end
