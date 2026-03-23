# frozen_string_literal: true

require_relative "../test_helper"

class NumberGeneratorTest < AceAssignTestCase
  def test_next_main_from_nil
    result = Ace::Assign::Atoms::NumberGenerator.next_main(nil)
    assert_equal "010", result
  end

  def test_next_main_from_existing
    result = Ace::Assign::Atoms::NumberGenerator.next_main("040")
    assert_equal "050", result
  end

  def test_next_main_rounds_up
    result = Ace::Assign::Atoms::NumberGenerator.next_main("045")
    assert_equal "050", result
  end

  def test_next_after_empty
    result = Ace::Assign::Atoms::NumberGenerator.next_after("040", [])
    assert_equal "041", result
  end

  def test_next_after_with_existing
    result = Ace::Assign::Atoms::NumberGenerator.next_after("040", ["041"])
    assert_equal "042", result
  end

  def test_next_after_with_multiple_existing
    result = Ace::Assign::Atoms::NumberGenerator.next_after("040", ["041", "042", "043"])
    assert_equal "044", result
  end

  def test_subtask_generation
    result = Ace::Assign::Atoms::NumberGenerator.subtask("030", 1)
    assert_equal "030.01", result
  end

  def test_subtask_generation_two_digit
    result = Ace::Assign::Atoms::NumberGenerator.subtask("030", 12)
    assert_equal "030.12", result
  end

  def test_sub_subtask_generation
    result = Ace::Assign::Atoms::NumberGenerator.sub_subtask("030.01", 1)
    assert_equal "030.01.01", result
  end

  def test_parse_main_number
    result = Ace::Assign::Atoms::NumberGenerator.parse("030")
    assert_equal({main: 30, parts: [30], depth: 1}, result)
  end

  def test_parse_subtask_number
    result = Ace::Assign::Atoms::NumberGenerator.parse("030.01")
    assert_equal({main: 30, parts: [30, 1], depth: 2}, result)
  end

  def test_parse_sub_subtask_number
    result = Ace::Assign::Atoms::NumberGenerator.parse("030.01.02")
    assert_equal({main: 30, parts: [30, 1, 2], depth: 3}, result)
  end

  def test_subtask_of_true
    assert Ace::Assign::Atoms::NumberGenerator.subtask_of?("030.01", "030")
  end

  def test_subtask_of_nested_true
    assert Ace::Assign::Atoms::NumberGenerator.subtask_of?("030.01.01", "030")
  end

  def test_subtask_of_false
    refute Ace::Assign::Atoms::NumberGenerator.subtask_of?("040", "030")
  end

  def test_from_index
    assert_equal "010", Ace::Assign::Atoms::NumberGenerator.from_index(0)
    assert_equal "020", Ace::Assign::Atoms::NumberGenerator.from_index(1)
    assert_equal "050", Ace::Assign::Atoms::NumberGenerator.from_index(4)
  end
end
