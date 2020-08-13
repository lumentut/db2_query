# frozen_string_literal: true

module DB2Query
  module Formatter
    def self.register(name, klass)
      self.format_registry.store(name.to_sym, klass.new)
    end

    def self.format_registry
      @@format_registry ||= Hash.new
    end

    def self.lookup(name)
      @@format_registry.fetch(name)
    end

    def self.registration(&block)
      yield self if block_given?
    end
  end

  class AbstractFormatter
    def format(value)
      raise DB2Query::Error, "Implement format method in your subclass."
    end
  end
end
