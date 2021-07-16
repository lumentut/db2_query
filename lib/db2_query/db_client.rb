# frozen_string_literal: true

module Db2Query
  class DbClient
    attr_reader :dsn

    delegate :run, :do, to: :client

    def initialize(config)
      @dsn = config[:dsn]
      @idle_time_limit = config[:idle] || 5
      @client = new_db_client
      @last_active = Time.now
    end

    def expire?
      Time.now - @last_active > 60 * @idle_time_limit
    end

    def active?
      @client.connected?
    end

    def connected_and_persist?
      active? && !expire?
    end

    def disconnect!
      @client.drop_all
      @client.disconnect if active?
      @client = nil
    end

    def new_db_client
      ODBC.connect(dsn)
    rescue ::ODBC::Error => e
      raise Db2Query::ConnectionError.new(e.message)
    end

    def client
      return @client if connected_and_persist?
      disconnect!
      @client = new_db_client
      @last_active = Time.now
      @client
    end
  end
end
