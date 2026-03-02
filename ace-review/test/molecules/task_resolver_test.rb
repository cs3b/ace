# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_resolver"

# Mock Ace::Task module structure for testing
# The actual ace-task gem is an optional dependency
module Ace
  module Task
    class Error < StandardError; end
    module Organisms
      class TaskManager
        def show(task_ref)
          raise NotImplementedError, "Mock not configured"
        end
      end
    end
  end
end

class TaskResolverTest < Minitest::Test
  def test_resolve_returns_nil_when_ace_task_not_available
    # Stub require to simulate ace-task not being installed
    Ace::Review::Molecules::TaskResolver.stub(:require, ->(_) { raise LoadError }) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")
      assert_nil result
    end
  end

  def test_resolve_returns_hash_with_path_for_valid_task
    mock_task = mock_task_struct(
      path: "/path/to/task/8pp.t.q7w-test-task",
      file_path: "/path/to/task/8pp.t.q7w-test-task/8pp.t.q7w-test-task.s.md",
      id: "8pp.t.q7w"
    )

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, mock_task, ["114"])

    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")

      assert_kind_of Hash, result
      assert_equal "/path/to/task/8pp.t.q7w-test-task", result[:path]
      assert_equal "/path/to/task/8pp.t.q7w-test-task/8pp.t.q7w-test-task.s.md", result[:spec_path]
      assert_equal "8pp.t.q7w", result[:task_id]
    end

    mock_task_manager.verify
  end

  def test_resolve_returns_nil_when_task_not_found
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, nil, ["999"])

    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("999")
      assert_nil result
    end

    mock_task_manager.verify
  end

  def test_resolve_returns_nil_when_task_has_no_path
    mock_task = mock_task_struct(
      path: "",
      file_path: "",
      id: "8pp.t.q7w"
    )

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, mock_task, ["114"])

    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("114")
      assert_nil result
    end

    mock_task_manager.verify
  end

  def test_resolve_handles_task_error_gracefully
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, nil) do |_ref|
      raise Ace::Task::Error, "Task not found"
    end

    captured_output = nil
    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      captured_output = capture_io do
        result = Ace::Review::Molecules::TaskResolver.resolve("invalid")
        assert_nil result
      end
    end

    assert_match(/Warning:.*could not be resolved/, captured_output[1])
  end

  def test_resolve_handles_unexpected_error_gracefully
    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, nil) do |_ref|
      raise RuntimeError, "Something unexpected happened"
    end

    captured_output = nil
    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      captured_output = capture_io do
        result = Ace::Review::Molecules::TaskResolver.resolve("114")
        assert_nil result
      end
    end

    assert_match(/Warning:.*Failed to resolve task/, captured_output[1])
  end

  def test_resolve_supports_b36ts_id_format
    mock_task = mock_task_struct(
      path: "/path/to/task/8pp.t.q7w-test-task",
      file_path: "/path/to/task/8pp.t.q7w-test-task/8pp.t.q7w-test-task.s.md",
      id: "8pp.t.q7w"
    )

    mock_task_manager = Minitest::Mock.new
    mock_task_manager.expect(:show, mock_task, ["8pp.t.q7w"])

    Ace::Task::Organisms::TaskManager.stub(:new, mock_task_manager) do
      result = Ace::Review::Molecules::TaskResolver.resolve("8pp.t.q7w")

      assert_kind_of Hash, result
      assert_equal "/path/to/task/8pp.t.q7w-test-task", result[:path]
    end

    mock_task_manager.verify
  end

  private

  def mock_task_struct(path:, file_path:, id:, title: "Test Task", status: "pending")
    task = Object.new
    task.define_singleton_method(:path) { path }
    task.define_singleton_method(:file_path) { file_path }
    task.define_singleton_method(:id) { id }
    task.define_singleton_method(:title) { title }
    task.define_singleton_method(:status) { status }
    task
  end
end
