# frozen_string_literal: true

module Db2Query
  module DataType
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      DATA_TYPES_MAP = {
        boolean:  Db2Query::Type::Boolean,
        varbinary: Db2Query::Type::Binary,
        binary: Db2Query::Type::Binary,
        string: Db2Query::Type::String,
        varchar: Db2Query::Type::Text,
        text: Db2Query::Type::Text,
        decimal: Db2Query::Type::Decimal,
        integer: ActiveRecord::Type::Integer,
        time: ActiveRecord::Type::Time,
        date: ActiveRecord::Type::Date,
        date_time: ActiveRecord::Type::DateTime,
        float: ActiveRecord::Type::Float
      }

      def data_types_map
        DATA_TYPES_MAP
      end
    end
  end
end
