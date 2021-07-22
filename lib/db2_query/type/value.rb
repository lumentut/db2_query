# frozen_string_literal: true

module Db2Query
  module Type
    class Value
      def type_name
        :value
      end

      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end
    end
  end
end
