# frozen_string_literal: true

module Db2Query
  module Type
    class Text < String
      def type
        :text
      end
    end
  end
end
