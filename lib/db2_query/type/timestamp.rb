# frozen_string_literal: true

module Db2Query
  module Type
    class Timestamp < Value
      def type
        :time
      end

      def serialize(value)
        if value.is_a?(::String)
          case value
          when  /\A(\d{4})-(\d\d)-(\d\d)-(\d\d).(\d\d).(\d\d).(\d{1,6})\z/
            quote(value)
          else
            nil
          end
        elsif value.is_a?(::DateTime) || value.is_a?(::Time)
          quote(value.strftime("%F-%H.%M.%S.%6N"))
        else
          nil
        end
      end

      def deserialize(value)
        value
      end
    end
  end
end
