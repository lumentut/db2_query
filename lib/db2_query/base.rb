# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include ConnectionHandler
    include Helper
    include Quoting
    include Core

    def self.inherited(subclass)
      subclass.define_query_definitions
    end
  end
end
