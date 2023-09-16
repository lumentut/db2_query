# frozen_string_literal: true

class BinaryTest < ActiveSupport::TestCase
  FIXTURES = %w(flowers.jpg example.log test.txt)

  test "binary encoding" do
    str = +"\x80"
    str.force_encoding("ASCII-8BIT")

    binary = BinaryQuery.insert name: "いただきます！", data: str

    assert_equal "いただきます！", binary.name
    assert_equal str, binary.data
  end

  test "insert binary files" do
    FileUtils.rm_rf("#{Dir.pwd}/test/assets/from_db/.", secure: true)

    FIXTURES.each do |file_name|
      file = File.read("#{Dir.pwd}/test/assets/#{file_name}")
      file.force_encoding("ASCII-8BIT")

      binary = BinaryQuery.insert name: file_name, data: file

      assert_equal file_name, binary.name
      assert_equal file, binary.data

      File.open("#{Dir.pwd}/test/assets/from_db/#{file_name}", "wb") { |f| f.write binary.data }
      new_file = File.read("#{Dir.pwd}/test/assets/from_db/#{file_name}")
      new_file.force_encoding("ASCII-8BIT")

      assert_equal file, new_file
    end
  end
end
