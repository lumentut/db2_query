# frozen_string_literal: true

class ResultTest < ActiveSupport::TestCase
  def result
    DB2Query::Result.new(["col_1", "col_2"], [
      ["row 1 col 1", "row 1 col 2"],
      ["row 2 col 1", "row 2 col 2"],
      ["row 3 col 1", "row 3 col 2"],
    ])
  end

  test "includes_column?" do
    assert result.includes_column?("col_1")
    assert_not result.includes_column?("foo")
  end

  test "length" do
    assert_equal 3, result.length
  end

  test "to_a returns row_hashes" do
    assert_equal [
      { "col_1" => "row 1 col 1", "col_2" => "row 1 col 2" },
      { "col_1" => "row 2 col 1", "col_2" => "row 2 col 2" },
      { "col_1" => "row 3 col 1", "col_2" => "row 3 col 2" },
    ], result.to_a
  end

  test "to_hash (deprecated) returns row_hashes" do
    assert_deprecated do
      assert_equal [
        { "col_1" => "row 1 col 1", "col_2" => "row 1 col 2" },
        { "col_1" => "row 2 col 1", "col_2" => "row 2 col 2" },
        { "col_1" => "row 3 col 1", "col_2" => "row 3 col 2" },
      ], result.to_hash
    end
  end

  test "first returns first row as a hash" do
    assert_equal(
      { "col_1" => "row 1 col 1", "col_2" => "row 1 col 2" }, result.first)
  end

  test "last returns last row as a hash" do
    assert_equal(
      { "col_1" => "row 3 col 1", "col_2" => "row 3 col 2" }, result.last)
  end

  test "each with block returns row hashes" do
    result.each do |row|
      assert_equal ["col_1", "col_2"], row.keys
    end
  end

  test "each without block returns an enumerator" do
    result.each.with_index do |row, index|
      assert_equal ["col_1", "col_2"], row.keys
      assert_kind_of Integer, index
    end
  end

  test "each without block returns a sized enumerator" do
    assert_equal 3, result.each.size
  end

  test "result records methods" do
    record1 = result.records.first
    assert_equal "DB2Query::Result::Record", record1.class.name
    assert_equal "row 1 col 1", record1.col_1
    assert_equal "row 1 col 2", record1.col_2

    record2 = result.records.last
    assert_equal "DB2Query::Result::Record", record2.class.name
    assert_equal "row 3 col 1", record2.col_1
    assert_equal "row 3 col 2", record2.col_2
  end
end
