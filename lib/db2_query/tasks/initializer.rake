# frozen_string_literal: true

DB2_QUERY_INITIALIZER_TEMPLATE ||= <<-EOF
# frozen_string_literal: true

# Example
require "db2_query/formatter"
class FirstNameFormatter < Db2Query::AbstractFormatter
  def format(value)
    "Dr." + value
  end
end

Db2Query::Formatter.registration do |format|
  format.register(:first_name_formatter, FirstNameFormatter)
end
EOF

namespace :db2query do
  desc "Create Initializer file"
  task :initializer do
    # Create initializer file
    initializer_path = "#{Rails.root}/config/initializers/db2query.rb"
    if File.exist?(initializer_path)
      raise ArgumentError, "File exists."
    else
      puts "  Creating initializer file ..."
      File.open(initializer_path, "w") do |file|
        file.puts DB2_QUERY_INITIALIZER_TEMPLATE
      end
      puts "  File '#{initializer_path}' created."
    end
  end
end