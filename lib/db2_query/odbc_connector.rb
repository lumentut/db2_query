# frozen_string_literal: true

module Db2Query
  class ODBCConnector
    attr_reader :connector, :conn_type, :conn_config

    CONNECTION_TYPES = %i[dsn conn_string].freeze

    def initialize(type, config)
      @conn_type, @conn_config = type, config.transform_keys(&:to_sym)
      @connector = Db2Query.const_get("#{conn_type.to_s.camelize}Connector").new
    end

    def connect
      connector.connect(conn_config)
    end
  end

  class DsnConnector
    def connect(config)
      ::ODBC.connect(config[:dsn], config[:uid], config[:pwd])
    rescue ::ODBC::Error => e
      raise Error, "Unable to activate ODBC DSN connection #{e}"
    end
  end

  class ConnStringConnector
    def connect(config)
      driver = ::ODBC::Driver.new.tap do |d|
        d.attrs = config[:conn_string].transform_keys(&:to_s)
        d.name = "odbc"
      end
      ::ODBC::Database.new.drvconnect(driver)
    rescue ::ODBC::Error => e
      raise Error, "Unable to activate ODBC Conn String connection #{e}"
    end
  end
end
