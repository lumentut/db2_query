# frozen_string_literal: true

module Db2Query
  module Type
    class Text < String
      DEFAULT = { limit: 32704, trim: false }

      def initialize(options = DEFAULT)
        super(options)
      end

      def type
        :text
      end
    end
  end
end
