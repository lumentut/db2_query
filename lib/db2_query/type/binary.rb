# frozen_string_literal: true

module Db2Query
  module Type
    class Binary
      def type
        :binary
      end

      def serialize(value)
        value.unpack1("H*")
      end

      def deserialize(value)
        [value].pack("H*")
      end
    end
  end
end
