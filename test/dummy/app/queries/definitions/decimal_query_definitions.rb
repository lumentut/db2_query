# frozen_string_literal: true

module Definitions
  class DecimalQueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :all do |c|
        c.id    :integer
        c.name  :string
        c.data_1  :decimal, precision: 7, scale: 2
        c.data_2  :decimal, precision: 7
      end

      query_definition :insert do |c|
        c.id    :integer
        c.name  :string
        c.data_1  :decimal, precision: 7, scale: 2
        c.data_2  :decimal, precision: 7
      end
    end
  end
end
