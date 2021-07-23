# frozen_string_literal: true

module Db2Query
  module Type
    class Boolean < Value
      TRUE_VALUES = [
        true, 1, "1", "t", "T",
        "true", "TRUE", "on", "ON",
        :"1", :t, :T, :true, :TRUE, :on, :ON
      ].freeze

      DEFAULT = { true: true, false: false }

      def initialize(options = DEFAULT)
        super(options)
      end

      def name
        :boolean
      end

      def serialize(value)
        case value
        when *TRUE_VALUES
          1
        else
          0
        end
      end

      def deserialize(value)
        case value
        when 1
          options[:true]
        else
          options[:false]
        end
      end
    end
  end
end
