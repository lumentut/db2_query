# frozen_String_literal: true

require 'odbc_utf8'

module DB2Query
  class ODBCConnector
    def self.new(type, config)
      conn_type, conn_config = type, config.transform_keys(&:to_sym)
      DB2Query.const_get("#{conn_type.to_s.camelize}Connector").new(conn_config)
    end
  end

  class AbstractConnector
    attr_reader :config

    def initialize(config)
      @config = config
    end
  end

  class DsnConnector < AbstractConnector
    def connect
      ::ODBC.connect(config[:dsn], config[:uid], config[:pwd])
    rescue ::ODBC::Error => e
      raise ArgumentError, "Unable to activate ODBC DSN connection #{e}"
    end
  end

  class ConnStringConnector < AbstractConnector
    def connect
      driver = ::ODBC::Driver.new.tap do |d|
        d.attrs = config[:conn_string].transform_keys(&:to_s)
        d.name = "odbc"
      end
      ::ODBC::Database.new.drvconnect(driver)
    rescue ::ODBC::Error => e
      raise ArgumentError, "Unable to activate ODBC Conn String connection #{e}"
    end
  end
end
