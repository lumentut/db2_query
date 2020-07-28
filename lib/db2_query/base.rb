# frozen_string_literal: true

module DB2Query
  class Base
    include DB2Query::Core
    include ActiveRecord::Inheritance
    extend ActiveSupport::Concern
    extend ActiveRecord::ConnectionHandling
    extend DB2Query::ConnectionHandling
  end
end
