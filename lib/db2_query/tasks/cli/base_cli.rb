# frozen_string_literal: true

require "thor"

class BaseCLI < Thor::Group
  include Thor::Actions

  class << self
    alias generate_file start
  end
end
