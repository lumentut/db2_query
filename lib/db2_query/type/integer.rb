# frozen_string_literal: true

module Db2Query
  module Type
    class Integer < Value
      def type
        :integer
      end

      def deserialize(value)
        value.to_i
      end
    end
  end
end
