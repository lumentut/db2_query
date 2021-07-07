# frozen_string_literal: true

module Db2Query
  class Base
    include Config
    include ConnectionHandler
    include Core
  end
end
