# frozen_string_literal: true

module Db2Query
  module Type
    class Date < Value
      def type
        :string
      end

      YMD_DATE = /\A(\d{4})-(\d\d)-(\d\d)\z/
      DMY_DATE = /\A(\d\d)-(\d\d)-(\d{4})\z/

      def serialize(value)
        if value.is_a?(::String)
          value = value.tr("/", "-")
          case value
          when YMD_DATE, DMY_DATE
            quote(::Date.parse(value))
          else
            nil
          end
        elsif value.is_a?(::Date)
          quote(value.strftime("%F"))
        else
          nil
        end
      end

      def deserialize(value)
        ::Date.parse(value.to_s)
      end
    end
  end
end
