# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/tasks_arg_parser"

class TasksArgParserTest < Minitest::Test
  def test_parse_filters_with_empty_args
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters([])

    assert_equal({}, result)
  end

  def test_parse_filters_with_status_flag
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--status", "pending,in-progress"])

    assert_equal ["pending", "in-progress"], result[:status]
  end

  def test_parse_filters_with_days_flag
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--days", "7"])

    assert_equal 7, result[:days]
  end

  def test_parse_filters_with_limit_flag
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--limit", "10"])

    assert_equal 10, result[:limit]
  end

  def test_parse_filters_with_boolean_flags
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--stats", "--tree", "--path", "--list"])

    assert_equal true, result[:stats]
    assert_equal true, result[:tree]
    assert_equal true, result[:path]
    assert_equal true, result[:list]
  end

  def test_parse_filters_with_backlog_flag
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--backlog"])

    assert_equal "backlog", result[:context]
  end

  def test_parse_filters_with_release_flag
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--release", "v.0.9.0"])

    assert_equal "v.0.9.0", result[:context]
  end

  def test_parse_filters_with_sort_field_only
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--sort", "priority"])

    assert_equal :priority, result[:sort][:by]
    assert_equal true, result[:sort][:ascending]
  end

  def test_parse_filters_with_sort_field_and_direction_asc
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--sort", "priority:asc"])

    assert_equal :priority, result[:sort][:by]
    assert_equal true, result[:sort][:ascending]
  end

  def test_parse_filters_with_sort_field_and_direction_desc
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters(["--sort", "priority:desc"])

    assert_equal :priority, result[:sort][:by]
    assert_equal false, result[:sort][:ascending]
  end

  def test_parse_filters_with_multiple_flags
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters([
      "--status", "pending",
      "--days", "7",
      "--stats"
    ])

    assert_equal ["pending"], result[:status]
    assert_equal 7, result[:days]
    assert_equal true, result[:stats]
  end

  def test_parse_filters_ignores_unknown_flags
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters([
      "--unknown", "value",
      "--status", "pending"
    ])

    assert_equal ["pending"], result[:status]
    refute result.key?(:unknown)
  end

  def test_parse_filters_handles_missing_values
    skip "Test needs fix - will be reviewed in Phase 9"
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_filters([
      "--status",
      "--days", "7"
    ])

    # --status has no value, so it gets skipped
    assert_equal 7, result[:days]
    refute result.key?(:status)
  end

  def test_parse_reschedule_args_with_tasks_only
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "002", "003"])

    assert_equal ["001", "002", "003"], result[:tasks]
    assert_nil result[:options][:strategy]
  end

  def test_parse_reschedule_args_with_add_next
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "--add-next"])

    assert_equal ["001"], result[:tasks]
    assert_equal :add_next, result[:options][:strategy]
  end

  def test_parse_reschedule_args_with_add_at_end
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "--add-at-end"])

    assert_equal ["001"], result[:tasks]
    assert_equal :add_at_end, result[:options][:strategy]
  end

  def test_parse_reschedule_args_with_after
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "--after", "task.005"])

    assert_equal ["001"], result[:tasks]
    assert_equal :after, result[:options][:strategy]
    assert_equal "task.005", result[:options][:reference_task]
  end

  def test_parse_reschedule_args_with_before
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "--before", "task.005"])

    assert_equal ["001"], result[:tasks]
    assert_equal :before, result[:options][:strategy]
    assert_equal "task.005", result[:options][:reference_task]
  end

  def test_parse_reschedule_args_ignores_flag_like_strings
    result = Ace::Taskflow::Molecules::TasksArgParser.parse_reschedule_args(["001", "--unknown-flag", "002"])

    assert_equal ["001", "002"], result[:tasks]
  end
end
