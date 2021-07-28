# frozen_string_literal: true

module Definitions
  class DatetimestampsQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id        :integer
        c.name      :string
        c.date      :date
        c.time      :time
        c.timestamp :timestamp
      end

      query_definition :insert do |c|
        c.id        :integer
        c.name      :string
        c.date      :date
        c.time      :time
        c.timestamp :timestamp
      end
    end
  end
end
