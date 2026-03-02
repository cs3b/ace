# frozen_string_literal: true

require "test_helper"
require "ace/task"
require "ace/task/organisms/task_manager"

class TaskPathResolverTest < Minitest::Test
  def setup
    @mock_manager = Minitest::Mock.new
  end

  def teardown
    @mock_manager.verify
  end

  # ============================================
  # Tests for resolve() - delegating to ace-task
  # ============================================

  def test_resolve_with_valid_task_id_returns_task_directory
    mock_task = mock_task_struct(
      path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature-name",
      file_path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature-name/8pp.t.q7w-feature-name.s.md",
      id: "8pp.t.q7w",
      title: "Feature Name"
    )

    @mock_manager.expect(:show, mock_task, ["117"])

    Ace::Task::Organisms::TaskManager.stub :new, @mock_manager do
      result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve("117")

      assert result[:found]
      assert_equal "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature-name", result[:path]
      assert_equal "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature-name/prompts", result[:prompts_path]
      assert_nil result[:error]
    end
  end

  def test_resolve_with_subtask_id_returns_subtask_directory
    mock_task = mock_task_struct(
      path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-ace-prep",
      file_path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-ace-prep/8pp.t.q7w-ace-prep.s.md",
      id: "8pp.t.q7w",
      title: "Archive Feature"
    )

    @mock_manager.expect(:show, mock_task, ["121.01"])

    Ace::Task::Organisms::TaskManager.stub :new, @mock_manager do
      result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve("121.01")

      assert result[:found]
      assert_equal "/project/.ace-tasks/8pp/t/8pp.t.q7w-ace-prep", result[:path]
      assert_equal "/project/.ace-tasks/8pp/t/8pp.t.q7w-ace-prep/prompts", result[:prompts_path]
      assert_nil result[:error]
    end
  end

  def test_resolve_with_qualified_id_returns_task_directory
    mock_task = mock_task_struct(
      path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature",
      file_path: "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature/8pp.t.q7w-feature.s.md",
      id: "8pp.t.q7w",
      title: "Feature"
    )

    @mock_manager.expect(:show, mock_task, ["8pp.t.q7w"])

    Ace::Task::Organisms::TaskManager.stub :new, @mock_manager do
      result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve("8pp.t.q7w")

      assert result[:found]
      assert_equal "/project/.ace-tasks/8pp/t/8pp.t.q7w-feature", result[:path]
    end
  end

  def test_resolve_with_non_existent_task_returns_error
    @mock_manager.expect(:show, nil, ["999"])

    Ace::Task::Organisms::TaskManager.stub :new, @mock_manager do
      result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve("999")

      refute result[:found]
      assert_nil result[:path]
      assert_nil result[:prompts_path]
      assert_includes result[:error], "Task not found: 999"
    end
  end

  def test_resolve_with_exception_returns_error
    def @mock_manager.show(_)
      raise StandardError, "Connection failed"
    end

    Ace::Task::Organisms::TaskManager.stub :new, @mock_manager do
      result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve("117")

      refute result[:found]
      assert_includes result[:error], "Error resolving task path"
      assert_includes result[:error], "Connection failed"
    end
  end


  # ============================================
  # Tests for extract_from_branch() - unchanged
  # ============================================

  def test_extract_from_branch_with_simple_task_id
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("117-feature-name")
    assert_equal "117", result
  end

  def test_extract_from_branch_with_subtask_id
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("121.01-archive")
    assert_equal "121.01", result
  end

  def test_extract_from_branch_with_main_returns_nil
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("main")
    assert_nil result
  end

  def test_extract_from_branch_with_number_not_at_start_returns_nil
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("feature-123")
    assert_nil result
  end

  def test_extract_from_branch_with_nil_returns_nil
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch(nil)
    assert_nil result
  end

  def test_extract_from_branch_with_empty_string_returns_nil
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("")
    assert_nil result
  end

  # Edge case: Real branch names from the project
  def test_extract_from_branch_with_subtask_in_branch_prefix
    # Actual branch pattern used in this PR: 121.06-12106-task-id-folder-support
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("121.06-12106-task-id-folder-support")
    assert_equal "121.06", result
  end

  def test_extract_from_branch_with_double_digit_subtask
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("121.10-fix-enhancement-flow")
    assert_equal "121.10", result
  end

  def test_extract_from_branch_with_just_number_prefix
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("42-answer-everything")
    assert_equal "42", result
  end

  def test_extract_from_branch_with_version_like_number
    # Ensure patterns like v.0.9.0 don't match (start with letter)
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("v.0.9.0-release")
    assert_nil result
  end

  # ============================================
  # Tests for configurable branch patterns
  # ============================================

  def test_extract_from_branch_with_custom_pattern
    # Test with custom pattern for feat/123-description style
    patterns = ['^(?:feat|fix|task)/(\d+)-']
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("feat/123-add-feature", patterns: patterns)
    assert_equal "123", result
  end

  def test_extract_from_branch_with_multiple_patterns
    # Test with multiple patterns - first match wins
    patterns = [
      '^(?:feat|fix)/(\d+)-',  # feat/123- or fix/123-
      '^(\d+(?:\.\d+)?)-'      # 123- or 123.01-
    ]

    # Should match first pattern
    result1 = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("fix/456-bugfix", patterns: patterns)
    assert_equal "456", result1

    # Should fall through to second pattern
    result2 = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("789-feature", patterns: patterns)
    assert_equal "789", result2
  end

  def test_extract_from_branch_with_no_matching_pattern
    patterns = ['^(?:feat|fix)/(\d+)-']
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("123-feature", patterns: patterns)
    assert_nil result
  end

  def test_extract_from_branch_with_empty_patterns_array
    # Empty patterns should return nil
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("123-feature", patterns: [])
    assert_nil result
  end

  def test_extract_from_branch_uses_config_when_patterns_nil
    # When patterns is nil, should use config (or default)
    # This test verifies backward compatibility
    result = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch("121-feature", patterns: nil)
    assert_equal "121", result
  end

  private

  def mock_task_struct(path:, file_path:, id:, title:, status: "pending")
    task = Object.new
    task.define_singleton_method(:path) { path }
    task.define_singleton_method(:file_path) { file_path }
    task.define_singleton_method(:id) { id }
    task.define_singleton_method(:title) { title }
    task.define_singleton_method(:status) { status }
    task
  end
end
