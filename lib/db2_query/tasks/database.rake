# frozen_string_literal: true

require "db2_query"

DB2_QUERY_DATABASE_TEMPLATE ||= <<-EOF
# frozen_string_literal: true

development:
  dsn: TODO
  pool: 5
  timeout: 5

test:
  dsn: TODO
  pool: 5
  timeout: 5

production:
  dsn: TODO
  pool: 5
  timeout: 5
EOF

namespace :db2query do
  desc "Create Database configuration file"
  task :database do
    database_path = "#{Rails.root}/config/db2query.yml"
    if File.exist?(database_path)
      raise Db2Query::Error, "Db2Query database config file exists, please check first"
    else
      puts "  Creating database config file ..."
      File.open(database_path, "w") do |file|
        file.puts DB2_QUERY_DATABASE_TEMPLATE
      end
      puts "  File '#{database_path}' created."
    end
  end
end
