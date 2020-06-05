# frozen_string_literal: true

module Db2Query
  module Path
    def self.database_config_file
      @@database_config_file ||= nil
    end

    def self.database_config_file=(file_path)
      @@database_config_file ||= file_path
    end

    def self.database_config_file_exists?
      File.exist?(self.database_config_file)
    end
  end
end
