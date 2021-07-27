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
        :wrong_extention_pointer,
        :insert_record,
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
    end
  end
end
