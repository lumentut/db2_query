# frozen_string_literal: true

module Db2Query
  module Type
    class String < Value
      DEFAULT = { trim: false }

      def initialize(options = DEFAULT)
        super(options)
      end

      def type
        :string
      end

      def deserialize(value)
        value.strip! if options[:trim]
        case value
        when ::String then
          if value == "null"
            nil
          else
            ::String.new(value)
          end
        else value.to_s
        end
      end
    end
  end
end
