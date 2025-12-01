# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_resolver"

# Mock Ace::Taskflow module structure for testing
# The actual ace-taskflow gem is an optional dependency
module Ace
  module Taskflow
    class Error < StandardError; end
    module Organisms
      class TaskManager
        def show_task(task_ref)
          raise NotImplementedError, "Mock not configured"
        end
      end
    end
  end
end

class TaskResolverTest < Minitest::Test
  def test_resolve_returns_nil_when_ace_taskflow_not_available
    # Stub require to simulate ace-taskflow not being installed
    Ace::Review::Molecules::TaskResolver.stub(:require, ->(_) { raise LoadError }) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")
      assert_nil result
    end
  end

  def test_resolve_returns_hash_with_path_for_valid_task
    # Create a mock task manager response
    mock_task = {
      path: "/path/to/task/114-test-task/task.114.s.md",
      task_number: 114,
      release: "v.0.9.0",
      id: "v.0.9.0+task.114"
    }

    # Create a mock TaskManager instance
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, mock_task, ["114"])

    # Stub TaskManager.new to return our mock
    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")

      assert_kind_of Hash, result
      assert_equal "/path/to/task/114-test-task", result[:path]
      assert_equal 114, result[:task_number]
      assert_equal "v.0.9.0", result[:release]
      assert_equal "v.0.9.0+task.114", result[:task_id]
    end

    mock_task_manager.verify
  end

  def test_resolve_returns_nil_when_task_not_found
    # Create a mock TaskManager that returns nil
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, nil, ["999"])

    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("999")
      assert_nil result
    end

    mock_task_manager.verify
  end

  def test_resolve_returns_nil_when_task_has_no_path
    # Task returned but missing path field
    mock_task = { task_number: 114, release: "v.0.9.0", id: "v.0.9.0+task.114" }

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, mock_task, ["114"])

    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")
      assert_nil result
    end

    mock_task_manager.verify
  end

  def test_resolve_handles_taskflow_error_gracefully
    # Create a mock TaskManager that raises an error
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, nil) do |_ref|
      raise Ace::Taskflow::Error, "Task not found"
    end

    # Capture stderr output
    captured_output = nil
    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      captured_output = capture_io do
        result = Ace::Review::Molecules::TaskResolver.resolve("invalid")
        assert_nil result
      end
    end

    # Should output a warning
    assert_match(/Warning:.*could not be resolved/, captured_output[1])
  end

  def test_resolve_handles_unexpected_error_gracefully
    # Create a mock TaskManager that raises an unexpected error
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, nil) do |_ref|
      raise RuntimeError, "Something unexpected happened"
    end

    # Capture stderr output
    captured_output = nil
    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      captured_output = capture_io do
        result = Ace::Review::Molecules::TaskResolver.resolve("114")
        assert_nil result
      end
    end

    # Should output a warning
    assert_match(/Warning:.*Failed to resolve task/, captured_output[1])
  end

  def test_resolve_supports_full_task_id_format
    mock_task = {
      path: "/path/to/task/114-test-task/task.114.s.md",
      task_number: 114,
      release: "v.0.9.0",
      id: "v.0.9.0+task.114"
    }

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, mock_task, ["v.0.9.0+114"])

    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("v.0.9.0+114")

      assert_kind_of Hash, result
      assert_equal "/path/to/task/114-test-task", result[:path]
    end

    mock_task_manager.verify
  end

  def test_resolve_supports_task_prefix_format
    mock_task = {
      path: "/path/to/task/114-test-task/task.114.s.md",
      task_number: 114,
      release: "v.0.9.0",
      id: "v.0.9.0+task.114"
    }

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show_task, mock_task, ["task.114"])

    Ace::Taskflow::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("task.114")

      assert_kind_of Hash, result
      assert_equal "/path/to/task/114-test-task", result[:path]
    end

    mock_task_manager.verify
  end
end
