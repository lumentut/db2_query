# frozen_string_literal: true

module Db2Query
  module Formatter
    def self.register(name, klass)
      self.registry.store(name, klass.new)
    end

    def self.registry
      @@registry ||= Hash.new
    end

    def self.lookup(name)
      @@registry.fetch(name.to_sym)
    end

    def self.registration(&block)
      yield self if block_given?
    end
  end

  class AbstractFormatter
    def format(value)
      raise NotImplementedError, "Implement format method in your subclass."
    end
  end

  class BareFormatter < AbstractFormatter
    def format(value)
      value
    end
  end

  class FloatFormatter < AbstractFormatter
    def format(value)
      value.to_f
    end
  end

  class IntegerFormatter < AbstractFormatter
    def format(value)
      value.to_i
    end
  end
end
