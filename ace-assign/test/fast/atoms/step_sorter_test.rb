# frozen_string_literal: true

require_relative "../../test_helper"

class StepSorterTest < AceAssignTestCase
  def test_sort_main_tasks
    files = ["020-bar.st.md", "010-foo.st.md", "030-baz.st.md"]
    result = Ace::Assign::Atoms::StepSorter.sort(files)
    assert_equal ["010-foo.st.md", "020-bar.st.md", "030-baz.st.md"], result
  end

  def test_sort_with_subtasks
    files = ["020-bar.st.md", "010-foo.st.md", "010.01-sub.st.md"]
    result = Ace::Assign::Atoms::StepSorter.sort(files)
    assert_equal ["010-foo.st.md", "010.01-sub.st.md", "020-bar.st.md"], result
  end

  def test_sort_with_sub_subtasks
    files = ["010.01.01-deep.st.md", "010-foo.st.md", "010.01-sub.st.md"]
    result = Ace::Assign::Atoms::StepSorter.sort(files)
    assert_equal ["010-foo.st.md", "010.01-sub.st.md", "010.01.01-deep.st.md"], result
  end

  def test_sort_with_injected
    files = ["040-test.st.md", "041-fix.st.md", "042-retry.st.md", "050-report.st.md"]
    result = Ace::Assign::Atoms::StepSorter.sort(files)
    assert_equal ["040-test.st.md", "041-fix.st.md", "042-retry.st.md", "050-report.st.md"], result
  end

  def test_sort_key_main
    result = Ace::Assign::Atoms::StepSorter.sort_key("010-foo.st.md")
    assert_equal [10, 0, 0], result
  end

  def test_sort_key_subtask
    result = Ace::Assign::Atoms::StepSorter.sort_key("010.01-bar.st.md")
    assert_equal [10, 1, 0], result
  end

  def test_sort_key_sub_subtask
    result = Ace::Assign::Atoms::StepSorter.sort_key("010.01.05-baz.st.md")
    assert_equal [10, 1, 5], result
  end

  def test_sort_numbers
    numbers = ["020", "010", "010.01"]
    result = Ace::Assign::Atoms::StepSorter.sort_numbers(numbers)
    assert_equal ["010", "010.01", "020"], result
  end

  def test_compare_less_than
    result = Ace::Assign::Atoms::StepSorter.compare("010", "020")
    assert_equal(-1, result)
  end

  def test_compare_equal
    result = Ace::Assign::Atoms::StepSorter.compare("010", "010")
    assert_equal 0, result
  end

  def test_compare_greater_than
    result = Ace::Assign::Atoms::StepSorter.compare("020", "010")
    assert_equal 1, result
  end

  def test_compare_subtask_after_main
    result = Ace::Assign::Atoms::StepSorter.compare("010.01", "010")
    assert_equal 1, result
  end
end
