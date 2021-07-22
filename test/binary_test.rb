# frozen_string_literal: true

require "test_helper"

class BinaryTest < ActiveSupport::TestCase
  FIXTURES = %w(flowers.jpg example.log test.txt)

  test "binary encoding" do
    str = +"\x80"
    str.force_encoding('ASCII-8BIT')

    binary = BinaryQuery.insert name: 'いただきます！', data: str

    assert_equal 'いただきます！', binary.name
    assert_equal str, binary.data
  end

  test "insert binary files" do
    FIXTURES.each do |file_name|
      file = File.read("#{Dir.pwd}/test/assets/#{file_name}")
      file.force_encoding('ASCII-8BIT')

      binary = BinaryQuery.insert name: file_name, data: file

      assert_equal file_name, binary.name
      assert_equal file, binary.data
    end
  end
end
