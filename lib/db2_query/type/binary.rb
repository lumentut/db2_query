# frozen_string_literal: true

module Db2Query
  module Type
    class Binary < Value
      def type
        :binary
      end

      def serialize(value)
        value.unpack1("H*")
      end

      def deserialize(value)
        Data.new(value)
      end

      class Data
        def initialize(value)
          @value = value.to_s
        end

        def to_s
          [@value].pack("H*")
        end
        alias_method :to_str, :to_s

        def hex
          @value.unpack1("H*")
        end

        def ==(other)
          other == to_s || super
        end
      end
    end
  end
end
