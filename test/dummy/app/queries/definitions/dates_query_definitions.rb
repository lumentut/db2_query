# frozen_string_literal: true

module Definitions
  class DatesQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data  :date
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data  :date
      end
    end
  end
end
