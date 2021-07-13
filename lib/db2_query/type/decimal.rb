# frozen_string_literal: true

require "delegate"

module Db2Query
  module Type
    class Decimal < Delegator
      attr_accessor :wrapped
      alias_method :__getobj__, :wrapped

      def initialize(**options)
        if options[:scale].nil?
          @wrapped = ActiveRecord::Type::DecimalWithoutScale.new(**options)
        else
          @wrapped = ActiveRecord::Type::Decimal.new(**options)
        end
      end
    end
  end
end
