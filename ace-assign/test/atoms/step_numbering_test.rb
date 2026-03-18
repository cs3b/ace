# frozen_string_literal: true

require_relative "../test_helper"

class StepNumberingTest < AceAssignTestCase
  # parse tests
  def test_parse_top_level_number
    result = Ace::Assign::Atoms::StepNumbering.parse("010")

    assert_equal "010", result[:full]
    assert_nil result[:parent]
    assert_equal 10, result[:index]
    assert_equal 0, result[:depth]
  end

  def test_parse_nested_number
    result = Ace::Assign::Atoms::StepNumbering.parse("010.02")

    assert_equal "010.02", result[:full]
    assert_equal "010", result[:parent]
    assert_equal 2, result[:index]
    assert_equal 1, result[:depth]
  end

  def test_parse_deeply_nested_number
    result = Ace::Assign::Atoms::StepNumbering.parse("010.02.03")

    assert_equal "010.02.03", result[:full]
    assert_equal "010.02", result[:parent]
    assert_equal 3, result[:index]
    assert_equal 2, result[:depth]
  end

  def test_parse_three_level_nesting
    result = Ace::Assign::Atoms::StepNumbering.parse("010.01.05.02")

    assert_equal "010.01.05.02", result[:full]
    assert_equal "010.01.05", result[:parent]
    assert_equal 2, result[:index]
    assert_equal 3, result[:depth]
  end

  # next_sibling tests
  def test_next_sibling_top_level
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("010")
    assert_equal "011", result
  end

  def test_next_sibling_top_level_high_number
    # Test that next_sibling works correctly with higher starting numbers
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("040")
    assert_equal "041", result
  end

  def test_next_sibling_nested
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("010.02")
    assert_equal "010.03", result
  end

  def test_next_sibling_deeply_nested
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("010.02.03")
    assert_equal "010.02.04", result
  end

  def test_next_sibling_first_child
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("010.01")
    assert_equal "010.02", result
  end

  def test_next_sibling_ninth_child
    result = Ace::Assign::Atoms::StepNumbering.next_sibling("010.09")
    assert_equal "010.10", result
  end

  # first_child tests
  def test_first_child_top_level
    result = Ace::Assign::Atoms::StepNumbering.first_child("010")
    assert_equal "010.01", result
  end

  def test_first_child_nested
    result = Ace::Assign::Atoms::StepNumbering.first_child("010.02")
    assert_equal "010.02.01", result
  end

  # next_child tests
  def test_next_child_no_existing
    result = Ace::Assign::Atoms::StepNumbering.next_child("010", [])
    assert_equal "010.01", result
  end

  def test_next_child_with_existing
    result = Ace::Assign::Atoms::StepNumbering.next_child("010", ["010.01", "010.02"])
    assert_equal "010.03", result
  end

  def test_next_child_ignores_grandchildren
    # Should only consider direct children, not grandchildren
    result = Ace::Assign::Atoms::StepNumbering.next_child("010", ["010.01", "010.01.01", "010.01.02"])
    assert_equal "010.02", result
  end

  def test_next_child_ignores_siblings
    result = Ace::Assign::Atoms::StepNumbering.next_child("010", ["020", "030"])
    assert_equal "010.01", result
  end

  # child_of? tests
  def test_child_of_direct_child
    assert Ace::Assign::Atoms::StepNumbering.child_of?("010.02", "010")
  end

  def test_child_of_grandchild
    assert Ace::Assign::Atoms::StepNumbering.child_of?("010.02.03", "010")
  end

  def test_child_of_nested_grandchild
    assert Ace::Assign::Atoms::StepNumbering.child_of?("010.02.03", "010.02")
  end

  def test_child_of_sibling_false
    refute Ace::Assign::Atoms::StepNumbering.child_of?("020", "010")
  end

  def test_child_of_self_false
    refute Ace::Assign::Atoms::StepNumbering.child_of?("010", "010")
  end

  def test_child_of_parent_false
    refute Ace::Assign::Atoms::StepNumbering.child_of?("010", "010.01")
  end

  # direct_child_of? tests
  def test_direct_child_of_true
    assert Ace::Assign::Atoms::StepNumbering.direct_child_of?("010.02", "010")
  end

  def test_direct_child_of_grandchild_false
    refute Ace::Assign::Atoms::StepNumbering.direct_child_of?("010.02.03", "010")
  end

  def test_direct_child_of_deeply_nested
    assert Ace::Assign::Atoms::StepNumbering.direct_child_of?("010.02.03", "010.02")
  end

  def test_direct_child_of_sibling_false
    refute Ace::Assign::Atoms::StepNumbering.direct_child_of?("020", "010")
  end

  # direct_children tests
  def test_direct_children
    all = ["010.01", "010.02", "010.01.01", "020"]
    result = Ace::Assign::Atoms::StepNumbering.direct_children("010", all)

    assert_equal ["010.01", "010.02"], result
  end

  def test_direct_children_empty
    all = ["020", "030"]
    result = Ace::Assign::Atoms::StepNumbering.direct_children("010", all)

    assert_equal [], result
  end

  # parent_of tests
  def test_parent_of_nested
    result = Ace::Assign::Atoms::StepNumbering.parent_of("010.02")
    assert_equal "010", result
  end

  def test_parent_of_deeply_nested
    result = Ace::Assign::Atoms::StepNumbering.parent_of("010.02.03")
    assert_equal "010.02", result
  end

  def test_parent_of_top_level
    result = Ace::Assign::Atoms::StepNumbering.parent_of("010")
    assert_nil result
  end

  # top_level? tests
  def test_top_level_true
    assert Ace::Assign::Atoms::StepNumbering.top_level?("010")
  end

  def test_top_level_false_nested
    refute Ace::Assign::Atoms::StepNumbering.top_level?("010.01")
  end

  def test_top_level_false_deeply_nested
    refute Ace::Assign::Atoms::StepNumbering.top_level?("010.01.01")
  end

  # insert_after tests
  def test_insert_after_basic
    result = Ace::Assign::Atoms::StepNumbering.insert_after("010.01")
    assert_equal "010.02", result
  end

  def test_insert_after_top_level
    result = Ace::Assign::Atoms::StepNumbering.insert_after("010")
    assert_equal "011", result
  end

  # steps_to_renumber tests
  def test_steps_to_renumber_basic
    existing = ["010.01", "010.02", "010.03"]
    result = Ace::Assign::Atoms::StepNumbering.steps_to_renumber("010.02", existing)

    assert_equal ["010.02", "010.03"], result
  end

  def test_steps_to_renumber_none_needed
    existing = ["010.01", "010.02", "010.03"]
    result = Ace::Assign::Atoms::StepNumbering.steps_to_renumber("010.04", existing)

    assert_equal [], result
  end

  def test_steps_to_renumber_ignores_different_parent
    existing = ["010.01", "010.02", "020.01", "020.02"]
    result = Ace::Assign::Atoms::StepNumbering.steps_to_renumber("010.02", existing)

    assert_equal ["010.02"], result
  end

  def test_steps_to_renumber_top_level
    existing = ["010", "020", "030"]
    result = Ace::Assign::Atoms::StepNumbering.steps_to_renumber("020", existing)

    assert_equal ["020", "030"], result
  end

  # shift_number tests
  def test_shift_number_nested
    result = Ace::Assign::Atoms::StepNumbering.shift_number("010.02", 1)
    assert_equal "010.03", result
  end

  def test_shift_number_top_level
    result = Ace::Assign::Atoms::StepNumbering.shift_number("020", 1)
    assert_equal "021", result
  end

  def test_shift_number_multiple
    result = Ace::Assign::Atoms::StepNumbering.shift_number("010.02", 3)
    assert_equal "010.05", result
  end

  def test_shift_number_deeply_nested
    result = Ace::Assign::Atoms::StepNumbering.shift_number("010.02.03", 1)
    assert_equal "010.02.04", result
  end
end
