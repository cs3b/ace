# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/models/task"

class TaskModelTest < AceTaskflowTestCase
  def setup
    @task_data = {
      id: "v.0.9.0+task.001",
      title: "Implement feature X",
      status: "pending",
      priority: "high",
      estimate: "4h",
      dependencies: ["v.0.9.0+task.002"],
      sort: 100,
      path: "/path/to/task.md",
      content: "Task description here",
      context: "v.0.9.0",
      task_number: "001",
      metadata: {}
    }
  end

  def test_task_initialization
    task = Ace::Taskflow::Models::Task.new(@task_data)

    assert_equal "v.0.9.0+task.001", task.id
    assert_equal "Implement feature X", task.title
    assert_equal "pending", task.status
    assert_equal "high", task.priority
    assert_equal "4h", task.estimate
    assert_equal ["v.0.9.0+task.002"], task.dependencies
    assert_equal 100, task.sort
  end

  def test_task_with_minimal_data
    minimal_data = {
      id: "task.001",
      title: "Minimal task"
    }
    task = Ace::Taskflow::Models::Task.new(minimal_data)

    assert_equal "task.001", task.id
    assert_equal "Minimal task", task.title
    assert_equal "pending", task.status  # Default status
    assert_equal "medium", task.priority  # Default priority
  end

  def test_task_status_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "pending", task.status
  end

  def test_task_priority_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "high", task.priority
  end

  def test_task_dependencies_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal ["v.0.9.0+task.002"], task.dependencies
  end

  def test_task_with_empty_dependencies
    data = @task_data.merge(dependencies: [])
    task = Ace::Taskflow::Models::Task.new(data)
    assert_equal [], task.dependencies
  end

  def test_task_with_nil_dependencies
    data = @task_data.dup
    data.delete(:dependencies)
    task = Ace::Taskflow::Models::Task.new(data)
    assert_equal [], task.dependencies
  end

  def test_task_metadata_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_instance_of Hash, task.metadata
  end

  def test_task_with_metadata
    data = @task_data.merge(metadata: { custom: "value" })
    task = Ace::Taskflow::Models::Task.new(data)
    assert_equal({ custom: "value" }, task.metadata)
  end

  def test_task_estimate_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "4h", task.estimate
  end

  def test_task_sort_value_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal 100, task.sort
  end

  def test_task_path_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "/path/to/task.md", task.path
  end

  def test_task_content_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "Task description here", task.content
  end

  def test_task_context_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "v.0.9.0", task.context
  end

  def test_task_number_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    assert_equal "001", task.task_number
  end

  def test_qualified_reference_accessor
    task = Ace::Taskflow::Models::Task.new(@task_data)
    # The qualified_reference uses task_number, not "task.XXX" format
    assert_equal "v.0.9.0+001", task.qualified_reference
  end

  def test_task_actionable_predicate
    pending_task = Ace::Taskflow::Models::Task.new(
      status: "pending",
      dependencies: []
    )
    assert pending_task.actionable?

    blocked_task = Ace::Taskflow::Models::Task.new(
      status: "pending",
      dependencies: ["task.002"]
    )
    refute blocked_task.actionable?
  end

  def test_task_done_predicate
    done_task = Ace::Taskflow::Models::Task.new(status: "done")
    assert done_task.done?

    pending_task = Ace::Taskflow::Models::Task.new(status: "pending")
    refute pending_task.done?
  end

  def test_task_in_progress_predicate
    in_progress_task = Ace::Taskflow::Models::Task.new(status: "in-progress")
    assert in_progress_task.in_progress?

    pending_task = Ace::Taskflow::Models::Task.new(status: "pending")
    refute pending_task.in_progress?
  end

  def test_task_blocked_predicate
    blocked_task = Ace::Taskflow::Models::Task.new(status: "blocked")
    assert blocked_task.blocked?

    pending_task = Ace::Taskflow::Models::Task.new(status: "pending")
    refute pending_task.blocked?
  end

  def test_task_to_hash
    task = Ace::Taskflow::Models::Task.new(@task_data)
    hash = task.to_h

    assert_instance_of Hash, hash
    assert_equal "v.0.9.0+task.001", hash[:id]
    assert_equal "Implement feature X", hash[:title]
    assert_equal "pending", hash[:status]
  end
end
