# frozen_string_literal: true

module Db2Query
  module Type
    class Binary < ActiveModel::Type::Value
      def type
        :binary
      end

      def binary?
        true
      end

      def cast(value)
        cast_value(value)
      end

      def serialize(value)
        value = "null" if value.nil?
        value.unpack1("H*")
      end

      class Data # :nodoc:
        def initialize(value)
          @value = value.to_s
        end

        def to_s
          @value
        end
        alias_method :to_str, :to_s

        def hex
          @value.unpack1("H*")
        end

        def ==(other)
          other == to_s || super
        end
      end

      private
        def cast_value(value)
          dt = !value[/\H/] ? [value].pack("H*") : value
          dt == "null" ? nil : dt
        end
    end
  end
end
