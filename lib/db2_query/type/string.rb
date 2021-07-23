# frozen_string_literal: true

module Db2Query
  module Type
    class String < Value
      DEFAULT = { limit: 255, trim: false }

      def initialize(options = DEFAULT)
        super(options)
      end

      def type
        :string
      end

      def deserialize(value)
        value = \
        case value
        when ::String then
          if value == "null"
            nil
          else
            ::String.new(value)
          end
        else value.to_s
        end
        value.strip! if options[:trim]
      end
    end
  end
end
