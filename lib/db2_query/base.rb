# frozen_string_literal: true

module DB2Query
  class Base
    include ActiveRecord::Inheritance
    include DB2Query::Core
    extend ActiveRecord::ConnectionHandling
    extend DB2Query::ConnectionHandling
  end
end
