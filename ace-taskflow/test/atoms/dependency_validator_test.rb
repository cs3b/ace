# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/dependency_validator"

class DependencyValidatorTest < AceTaskflowTestCase
  def setup
    @validator = Ace::Taskflow::Atoms::DependencyValidator
    @tasks = [
      { id: "task.001", dependencies: [] },
      { id: "task.002", dependencies: ["task.001"] },
      { id: "task.003", dependencies: ["task.002"] },
      { id: "task.004", dependencies: [] }
    ]
    @task_map = @tasks.each_with_object({}) { |t, map| map[t[:id]] = t }
  end

  def test_valid_reference_returns_true_for_existing_task
    assert @validator.valid_reference?("task.001", @task_map)
    assert @validator.valid_reference?("task.002", @task_map)
  end

  def test_valid_reference_returns_false_for_missing_task
    refute @validator.valid_reference?("task.999", @task_map)
  end

  def test_valid_reference_handles_nil_dependency
    refute @validator.valid_reference?(nil, @task_map)
  end

  def test_valid_reference_handles_empty_dependency
    refute @validator.valid_reference?("", @task_map)
  end

  def test_self_dependency_detection
    assert @validator.self_dependency?("task.001", "task.001")
    refute @validator.self_dependency?("task.001", "task.002")
  end

  def test_would_create_cycle_detects_simple_cycle
    # task.001 -> task.002, adding task.002 -> task.001 would create cycle
    refute @validator.would_create_cycle?("task.001", "task.002", @task_map)
    assert @validator.would_create_cycle?("task.001", "task.003", @task_map)
  end

  def test_would_create_cycle_with_no_cycle
    refute @validator.would_create_cycle?("task.004", "task.001", @task_map)
  end

  def test_find_circular_path_returns_nil_when_no_cycle
    path = @validator.find_circular_path("task.004", "task.001", @task_map)
    assert_nil path
  end

  def test_find_circular_path_returns_path_when_cycle_exists
    path = @validator.find_circular_path("task.001", "task.003", @task_map)

    refute_nil path
    assert path.first == "task.001"
    assert path.last == "task.001"
  end

  def test_validate_task_dependencies_with_valid_dependencies
    task = { id: "task.002", dependencies: ["task.001"] }
    result = @validator.validate_task_dependencies(task, @tasks)

    assert result[:valid]
    assert_empty result[:errors]
  end

  def test_validate_task_dependencies_with_missing_dependency
    task = { id: "task.005", dependencies: ["task.999"] }
    result = @validator.validate_task_dependencies(task, @tasks)

    refute result[:valid]
    assert_includes result[:errors].join, "does not exist"
  end

  def test_validate_task_dependencies_with_self_dependency
    task = { id: "task.001", dependencies: ["task.001"] }
    result = @validator.validate_task_dependencies(task, @tasks)

    refute result[:valid]
    assert_includes result[:errors].join, "cannot depend on itself"
  end

  def test_validate_task_dependencies_with_circular_dependency
    circular_tasks = [
      { id: "task.001", dependencies: ["task.002"] },
      { id: "task.002", dependencies: ["task.001"] }
    ]

    task = circular_tasks.first
    result = @validator.validate_task_dependencies(task, circular_tasks)

    refute result[:valid]
    assert_includes result[:errors].join, "Circular dependency"
  end

  def test_validate_task_dependencies_with_no_dependencies
    task = { id: "task.001", dependencies: [] }
    result = @validator.validate_task_dependencies(task, @tasks)

    assert result[:valid]
    assert_empty result[:errors]
  end

  def test_validate_task_dependencies_with_nil_dependencies
    task = { id: "task.001", dependencies: nil }
    result = @validator.validate_task_dependencies(task, @tasks)

    assert result[:valid]
    assert_empty result[:errors]
  end

  def test_validate_all_dependencies_returns_only_invalid_tasks
    all_tasks = [
      { id: "task.001", dependencies: [] },
      { id: "task.002", dependencies: ["task.999"] },  # Invalid
      { id: "task.003", dependencies: ["task.001"] }   # Valid
    ]

    results = @validator.validate_all_dependencies(all_tasks)

    assert_equal 1, results.size
    assert results.key?("task.002")
    refute results.key?("task.001")
    refute results.key?("task.003")
  end

  def test_validate_all_dependencies_with_all_valid
    results = @validator.validate_all_dependencies(@tasks)

    assert_empty results
  end

  def test_validate_task_dependencies_with_multiple_errors
    task = {
      id: "task.005",
      dependencies: ["task.999", "task.888", "task.005"]
    }
    result = @validator.validate_task_dependencies(task, @tasks)

    refute result[:valid]
    assert result[:errors].length >= 2
  end

  def test_validate_task_dependencies_with_indirect_cycle
    cycle_tasks = [
      { id: "task.001", dependencies: ["task.002"] },
      { id: "task.002", dependencies: ["task.003"] },
      { id: "task.003", dependencies: ["task.001"] }
    ]

    task = cycle_tasks.first
    result = @validator.validate_task_dependencies(task, cycle_tasks)

    refute result[:valid]
    assert_includes result[:errors].join, "Circular"
  end
end
