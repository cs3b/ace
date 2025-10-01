# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_statistics"

class TaskStatisticsTest < Minitest::Test
  def test_calculate_returns_empty_for_nil
    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(nil)

    assert_equal 0, result[:total]
    assert_equal({}, result[:by_status])
  end

  def test_calculate_returns_empty_for_empty_array
    result = Ace::Taskflow::Molecules::TaskStatistics.calculate([])

    assert_equal 0, result[:total]
    assert_equal({}, result[:by_status])
  end

  def test_calculate_counts_total
    tasks = [
      { id: "task.001", status: "pending" },
      { id: "task.002", status: "done" },
      { id: "task.003", status: "in-progress" }
    ]

    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(tasks)

    assert_equal 3, result[:total]
  end

  def test_calculate_counts_by_status
    tasks = [
      { id: "task.001", status: "pending" },
      { id: "task.002", status: "pending" },
      { id: "task.003", status: "done" },
      { id: "task.004", status: "in-progress" }
    ]

    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(tasks)

    assert_equal 2, result[:by_status]["pending"]
    assert_equal 1, result[:by_status]["done"]
    assert_equal 1, result[:by_status]["in-progress"]
  end

  def test_calculate_counts_by_priority
    tasks = [
      { id: "task.001", priority: "high" },
      { id: "task.002", priority: "high" },
      { id: "task.003", priority: "low" },
      { id: "task.004", priority: "medium" }
    ]

    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(tasks)

    assert_equal 2, result[:by_priority]["high"]
    assert_equal 1, result[:by_priority]["low"]
    assert_equal 1, result[:by_priority]["medium"]
  end

  def test_calculate_counts_by_context
    tasks = [
      { id: "task.001", context: "v.0.9.0" },
      { id: "task.002", context: "v.0.9.0" },
      { id: "task.003", context: "backlog" }
    ]

    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(tasks)

    assert_equal 2, result[:by_context]["v.0.9.0"]
    assert_equal 1, result[:by_context]["backlog"]
  end

  def test_calculate_handles_missing_attributes
    tasks = [
      { id: "task.001" },  # No status, priority, context
      { id: "task.002", status: "pending" }
    ]

    result = Ace::Taskflow::Molecules::TaskStatistics.calculate(tasks)

    assert_equal 2, result[:total]
    assert_equal 1, result[:by_status]["unknown"]
    assert_equal 1, result[:by_status]["pending"]
  end

  def test_empty_stats_structure
    result = Ace::Taskflow::Molecules::TaskStatistics.empty_stats

    assert_equal 0, result[:total]
    assert_equal({}, result[:by_status])
    assert_equal({}, result[:by_priority])
    assert_equal({}, result[:by_context])
  end
end
