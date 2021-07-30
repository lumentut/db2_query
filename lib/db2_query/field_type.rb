# frozen_string_literal: true

module Db2Query
  module FieldType
    DEFAULT_FIELD_TYPES = {
      binary: Db2Query::Type::Binary,
      boolean:  Db2Query::Type::Boolean,
      string: Db2Query::Type::String,
      varchar: Db2Query::Type::String,
      longvarchar: Db2Query::Type::String,
      decimal: Db2Query::Type::Decimal,
      integer: Db2Query::Type::Integer,
      date: Db2Query::Type::Date,
      time: Db2Query::Type::Time,
      timestamp: Db2Query::Type::Timestamp
    }

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      mattr_reader :field_types_map
      @@field_types_map = nil

      def set_field_types(types = DEFAULT_FIELD_TYPES)
        @@field_types_map = types
      end
    end
  end
end
