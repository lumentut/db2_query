# frozen_string_literal: true

module Db2Query
  class DbClient
    attr_reader :dsn

    include ActiveModel::Type::Helpers::Timezone

    delegate :run, :do, to: :client

    def initialize(config)
      @dsn = config[:dsn]
      @idle_time_limit = config[:idle] || 5
      @client = new_client
      @last_transaction = Time.now
    end

    def expire?
      Time.now - @last_transaction > 60 * @idle_time_limit
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

    def new_client
      ODBC.connect(dsn).tap do |odbc_conn|
        odbc_conn.use_time = true
        odbc_conn.use_utc = is_utc?
      end
    rescue ::ODBC::Error => e
      raise Db2Query::ConnectionError.new(e.message)
    end

    def reconnect!
      disconnect!
      @client = new_client
    end

    def client
      reconnect! unless connected_and_persist?
      @last_transaction = Time.now
      @client
    end
  end
end
