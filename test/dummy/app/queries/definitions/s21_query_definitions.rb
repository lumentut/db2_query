# frozen_string_literal: true

module Definitions
  class S21QueryDefinitions < Db2Query::Definitions
    def describe
      query_definition :by_icno do |c|
        c.pnum60  :string
        c.iunt60  :string
        c.sphy60  :integer
        c.soor60  :integer
        c.salc60  :integer
        c.sbor60  :integer
        c.savl60  :integer
        c.sfrz60  :integer
        c.spnt60  :integer
        c.sorsv60 :integer
        c.sits60  :integer
        c.dlis60  :integer
        c.dlrc60  :integer
      end

      query_definition :details do |c|
        c.pnum60  :string
        c.iunt60  :string
        c.sphy60  :integer
        c.soor60  :integer
        c.salc60  :integer
        c.sbor60  :integer
        c.savl60  :integer
        c.sfrz60  :integer
        c.spnt60  :integer
        c.sorsv60 :integer
        c.sits60  :integer
        c.dlis60  :integer
        c.dlrc60  :integer
      end
    end
  end
end