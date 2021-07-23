# frozen_string_literal: true

module Definitions
  class BooleanQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data  :boolean, true: :T, false: :F
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data  :boolean
      end
    end
  end
end
