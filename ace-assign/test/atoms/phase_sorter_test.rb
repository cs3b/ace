# frozen_string_literal: true

require_relative "../test_helper"

class PhaseSorterTest < AceAssignTestCase
  def test_sort_main_tasks
    files = ["020-bar.ph.md", "010-foo.ph.md", "030-baz.ph.md"]
    result = Ace::Assign::Atoms::PhaseSorter.sort(files)
    assert_equal ["010-foo.ph.md", "020-bar.ph.md", "030-baz.ph.md"], result
  end

  def test_sort_with_subtasks
    files = ["020-bar.ph.md", "010-foo.ph.md", "010.01-sub.ph.md"]
    result = Ace::Assign::Atoms::PhaseSorter.sort(files)
    assert_equal ["010-foo.ph.md", "010.01-sub.ph.md", "020-bar.ph.md"], result
  end

  def test_sort_with_sub_subtasks
    files = ["010.01.01-deep.ph.md", "010-foo.ph.md", "010.01-sub.ph.md"]
    result = Ace::Assign::Atoms::PhaseSorter.sort(files)
    assert_equal ["010-foo.ph.md", "010.01-sub.ph.md", "010.01.01-deep.ph.md"], result
  end

  def test_sort_with_injected
    files = ["040-test.ph.md", "041-fix.ph.md", "042-retry.ph.md", "050-report.ph.md"]
    result = Ace::Assign::Atoms::PhaseSorter.sort(files)
    assert_equal ["040-test.ph.md", "041-fix.ph.md", "042-retry.ph.md", "050-report.ph.md"], result
  end

  def test_sort_key_main
    result = Ace::Assign::Atoms::PhaseSorter.sort_key("010-foo.ph.md")
    assert_equal [10, 0, 0], result
  end

  def test_sort_key_subtask
    result = Ace::Assign::Atoms::PhaseSorter.sort_key("010.01-bar.ph.md")
    assert_equal [10, 1, 0], result
  end

  def test_sort_key_sub_subtask
    result = Ace::Assign::Atoms::PhaseSorter.sort_key("010.01.05-baz.ph.md")
    assert_equal [10, 1, 5], result
  end

  def test_sort_numbers
    numbers = ["020", "010", "010.01"]
    result = Ace::Assign::Atoms::PhaseSorter.sort_numbers(numbers)
    assert_equal ["010", "010.01", "020"], result
  end

  def test_compare_less_than
    result = Ace::Assign::Atoms::PhaseSorter.compare("010", "020")
    assert_equal(-1, result)
  end

  def test_compare_equal
    result = Ace::Assign::Atoms::PhaseSorter.compare("010", "010")
    assert_equal 0, result
  end

  def test_compare_greater_than
    result = Ace::Assign::Atoms::PhaseSorter.compare("020", "010")
    assert_equal 1, result
  end

  def test_compare_subtask_after_main
    result = Ace::Assign::Atoms::PhaseSorter.compare("010.01", "010")
    assert_equal 1, result
  end
end
