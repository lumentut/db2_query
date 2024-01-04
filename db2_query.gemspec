require_relative "lib/db2_query/version"

Gem::Specification.new do |spec|
  spec.name        = "db2_query"
  spec.version     = Db2Query::VERSION
  spec.authors     = ["Yohanes Lumentut"]
  spec.email       = ["yohanes.lumentut@gmail.com"]
  spec.homepage    = "https://github.com/yohaneslumentut/db2_query"
  spec.summary     = "Rails Db2 ODBC plugin"
  spec.description = "A Rails 7 (Ruby v3.1.0) plugin for connecting Db2 with Rails appplication by using ODBC connection."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yohaneslumentut/db2_query"
  spec.metadata["changelog_uri"] = "https://github.com/yohaneslumentut/db2_query"
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.2"
  spec.add_development_dependency "tty-progressbar"
  spec.add_development_dependency "faker"
  spec.add_dependency "connection_pool"
  # spec.add_dependency "ruby-odbc"
end
