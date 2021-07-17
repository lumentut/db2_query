# frozen_string_literal: true

module Definitions
  class DefinitionsQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :details do |c|
        c.name        :varchar
        c.description :others
      end
    end
  end
end
