class BaseCLI < Thor::Group
  include Thor::Actions

  class << self
    alias generate_file start
  end
end
