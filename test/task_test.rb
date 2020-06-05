# frozen_string_literal: true

require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    ["initializers/db2query.rb", "db2query_database.yml"].each do |file|
      File.delete("#{Rails.root}/config/#{file}")
    end
    Dummy::Application.load_tasks
  end

  def test_exception
    assert_nothing_raised do
      Rake::Task["db2query:init"].invoke
    end

    exception1 = assert_raise(Exception) { Rake::Task["db2query:initializer"].execute }
    assert_equal("File exists.", exception1.message)

    exception2 = assert_raise(Exception) { Rake::Task["db2query:database"].execute }
    assert_equal("File exists.", exception2.message)
  end
end
