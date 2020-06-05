# frozen_string_literal: true

DB2_QUERY_DATABASE_TEMPLATE ||= <<-EOF
# frozen_string_literal: true

# Database configuration example
development:
  primary:
    conn_string:
      driver: DB2
      database: SAMPLE
      dbalias: SAMPLE
      hostname: LOCALHOST
      currentschema: LIBTEST
      port: "0"
      protocol: IPC
      uid: <%= ENV["DB2EC_UID"] %>
      pwd: <%= ENV["DB2EC_PWD"] %>
  secondary:
    dsn: SAMPLE
    uid: <%= ENV["DB2EC_UID"] %>
    pwd: <%= ENV["DB2EC_PWD"] %>

test:
  primary:
    conn_string:
      driver: DB2
      database: SAMPLE
      dbalias: SAMPLE
      hostname: LOCALHOST
      currentschema: LIBTEST
      port: "0"
      protocol: IPC
      uid: <%= ENV["DB2EC_UID"] %>
      pwd: <%= ENV["DB2EC_PWD"] %>
  secondary:
    dsn: SAMPLE
    uid: <%= ENV["DB2EC_UID"] %>
    pwd: <%= ENV["DB2EC_PWD"] %>
EOF

namespace :db2query do
  desc "Create Database configuration file"
  task :database do
    database_path = "#{Rails.root}/config/db2query_database.yml"
    if File.exist?(database_path)
      raise ArgumentError, "File exists."
    else
      puts "  Creating database config file ..."
      File.open(database_path, "w") do |file|
        file.puts DB2_QUERY_DATABASE_TEMPLATE
      end
      puts "  File '#{database_path}' created."
    end
  end
end
