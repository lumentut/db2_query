# frozen_string_literal: true

module Db2Query
  module Type
    class Boolean < ActiveModel::Type::Value
      FALSE_VALUES = [
        false, 0,
        "0", :"0",
        "f", :f,
        "F", :F,
        "false", :false,
        "FALSE", :FALSE,
        "off", :off,
        "OFF", :OFF,
      ].to_set.freeze

      def type # :nodoc:
        :boolean
      end

      def serialize(value) # :nodoc:
        cast(value)
      end

      def cast(value)
        cast_value(value)
      end

      private
        def cast_value(value)
          case value
          when *["-1", -1, ""]
            nil
          when nil
            "-1"
          else
            !FALSE_VALUES.include?(value)
          end
        end
    end
  end
end
