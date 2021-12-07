# frozen_string_literal: true

module Definitions
  class UserQueryDefinitions < Db2Query::Definitions
    def describe
      queries = [
        :all,
        :by_id,
        :by_first_name_and_email,
        :by_last_name_and_email,
        :find_by,
        :id_gt,
        :id_greater_than,
        :by_first_name_and_last_name,
        :by_ids,
        :by_names,
        :by_details,
        :by_email,
        :by_first_name,
        :by_first_names,
        :by_last_name,
        :wrong_list_pointer,
        :wrong_extension_pointer,
        :insert_record,
        :insert_fetch,
        :update_record,
        :delete_record
      ]

      queries.each do |query|
        query_definition query do |c|
          c.id          :integer
          c.first_name  :varchar
          c.last_name   :varchar
          c.email       :varchar
        end
      end

      query_definition :mailto do |c|
        c.id          :integer
        c.first_name  :string
        c.last_name   :string
        c.mailto      :string
      end
    end
  end
end
