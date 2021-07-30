# frozen_string_literal: true

module Db2Query
  module Type
    class Value
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def type_name
        :value
      end

      def serialize(value)
        value
      end

      def deserialize(value)
        value
      end

      def quote(value)
        "'#{value}'"
      end
    end
  end
end
