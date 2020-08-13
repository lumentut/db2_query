# frozen_string_literal: true

$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "db2_query/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "db2_query"
  spec.version     = DB2Query::VERSION
  spec.authors     = ["yohanes_l"]
  spec.email       = ["yohanes.lumentut@yahoo.com"]
  spec.summary     = "DB2Query"
  spec.description = "A Rails query plugin to fetch data from Db2 database by using ODBC connection."
  spec.homepage    = "https://github.com/yohaneslumentut/db2_query"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "ruby-odbc", "~> 0.99999"
  spec.add_dependency "activesupport", "~> 6.0.3"
  spec.add_dependency "activerecord", "~> 6.0.3"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "byebug"
end
