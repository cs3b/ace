# frozen_string_literal: true

require "minitest/autorun"

# Sample test file for integration testing
class SampleTestFile < Minitest::Test
  def test_first_example
    assert_equal 2, 1 + 1
  end

  def test_second_example
    assert true
  end

  def test_third_example
    assert_equal "hello", "hel" + "lo"
  end

  def test_fourth_example
    refute false
  end

  def test_fifth_example
    assert_includes [1, 2, 3], 2
  end
end
