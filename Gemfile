source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in db2_query.gemspec.
gemspec

gem "ruby-odbc", github: "yohaneslumentut/ruby-odbc"

group :development, :test do
  gem "puma"
  gem "sqlite3"
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
