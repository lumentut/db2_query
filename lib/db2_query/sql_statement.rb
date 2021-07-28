# frozen_string_literal: true

module Db2Query
  module SqlStatement
    def delete_sql?
      sql.match?(/delete/i)
    end

    def insert_sql?
      sql.match?(/insert/i)
    end

    def iud_sql?
      sql.match?(/insert into|update|delete/i)
    end

    def db2_spec_sql
      iud_sql? ? iud_spec_sql : sql
    end

    def table_name
      insert_sql? ? sql.split("INTO ").last.split(" ").first : nil
    end

    private
      def new_keys(raw_sql)
        raw_sql.scan(/\$\S+/).map { |key| key.gsub!(/[$=,)]/, "").to_sym }
      end

      def iud_spec_sql
        "SELECT * FROM #{delete_sql? ? "OLD" : "NEW"} TABLE (#{sql})"
      end
  end
end
