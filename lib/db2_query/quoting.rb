# frozen_string_literal: true

module Db2Query
  module Quoting
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def quoted_true
        "TRUE"
      end

      def unquoted_true
        1
      end

      def quoted_false
        "FALSE"
      end

      def unquoted_false
        0
      end

      def quoted_binary(value)
        "x'#{value.hex}'"
      end

      def quoted_time(value)
        value = value.change(year: 2000, month: 1, day: 1)
        quoted_date(value).sub(/\A\d\d\d\d-\d\d-\d\d /, "")
      end

      def quoted_date(value)
        if value.acts_like?(:time)
          if ActiveRecord::Base.default_timezone == :utc
            value = value.getutc if !value.utc?
          else
            value = value.getlocal
          end
        end

        result = value.to_s(:db)
        if value.respond_to?(:usec) && value.usec > 0
          result << "." << sprintf("%06d", value.usec)
        else
          result
        end
      end

      private
        def _quote(value)
          case value
          when String, Symbol, ActiveSupport::Multibyte::Chars
            "'#{quote_string(value.to_s)}'"
          when true
            quoted_true
          when false
            quoted_false
          when nil
            "NULL"
          when BigDecimal
            value.to_s("F")
          when Numeric, ActiveSupport::Duration
            value.to_s
          when Db2Query::Type::Binary::Data
            quoted_binary(value)
          when ActiveRecord::Type::Time::Value
            "'#{quoted_time(value)}'"
          when Date, Time
            "'#{quoted_date(value)}'"
          when Class
            "'#{value}'"
          else raise TypeError, "can't quote #{value.class.name}"
          end
        end

        def _type_cast(value)
          case value
          when Symbol, ActiveSupport::Multibyte::Chars
            value.to_s
          when Db2Query::Type::Binary::Data
            value.hex
          when true
            unquoted_true
          when false
            unquoted_false
          when BigDecimal
            value.to_s("F")
          when nil, Numeric, String
            value
          when ActiveRecord::Type::Time::Value
            quoted_time(value)
          when Date, Time
            quoted_date(value)
          else raise TypeError, "can't cast #{value.class.name}"
          end
        end
    end
  end
end
