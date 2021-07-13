# frozen_string_literal: true

module Db2Query
  module Type
    class String < ActiveModel::Type::String
      private
        def cast_value(value)
          case value
          when ::String then
            if value == "null"
              nil
            else
              ::String.new(value)
            end
          when true then "t"
          when false then "f"
          else value.to_s
          end
        end
    end
  end
end
