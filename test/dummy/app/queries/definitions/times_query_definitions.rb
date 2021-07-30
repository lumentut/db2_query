# frozen_string_literal: true

module Definitions
  class TimesQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data  :time
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data  :time
      end
    end
  end
end
