# frozen_string_literal: true

module DB2Query
  class Bind < Struct.new(:name, :value, :index)
  end
end
