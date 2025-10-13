# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/path_builder"
require "ostruct"

class PathBuilderTest < AceTaskflowTestCase
  def setup
    @builder = Ace::Taskflow::Atoms::PathBuilder
    @root = "/path/to/.ace-taskflow"
    @mock_config = OpenStruct.new(task_dir: "tasks")
  end

  # Helper to run tests with stubbed config
  def with_config(&block)
    @builder.stub :config, @mock_config, &block
  end

  def test_build_task_path_without_slug
    with_config do
      result = @builder.build_task_path(@root, "v.0.9.0", "001")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/001", result
    end
  end

  def test_build_task_path_with_slug
    with_config do
      result = @builder.build_task_path(@root, "v.0.9.0", "025", "feat-taskflow-idea")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/025-feat-taskflow-idea", result
    end
  end

  def test_build_task_path_pads_task_number
    with_config do
      result = @builder.build_task_path(@root, "v.0.9.0", 5, "fix-bug")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/005-fix-bug", result
    end
  end

  def test_build_task_path_in_backlog
    with_config do
      result = @builder.build_task_path(@root, "backlog", "042", "feature-x")

      assert_equal "/path/to/.ace-taskflow/backlog/tasks/042-feature-x", result
    end
  end

  def test_build_task_file_path_without_slug
    with_config do
      result = @builder.build_task_file_path(@root, "v.0.9.0", "001")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/001/task.md", result
    end
  end

  def test_build_task_file_path_with_slug
    with_config do
      result = @builder.build_task_file_path(@root, "v.0.9.0", "025", nil, "feat-idea")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/025-feat-idea/task.025.md", result
    end
  end

  def test_build_task_file_path_with_custom_filename
    with_config do
      result = @builder.build_task_file_path(@root, "v.0.9.0", "001", "custom.md")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/001/custom.md", result
    end
  end

  def test_build_release_path_active
    result = @builder.build_release_path(@root, "v.0.9.0", "active")

    assert_equal "/path/to/.ace-taskflow/v.0.9.0", result
  end

  def test_build_release_path_backlog
    result = @builder.build_release_path(@root, "v.1.0.0", "backlog")

    assert_equal "/path/to/.ace-taskflow/backlog/v.1.0.0", result
  end

  def test_build_release_path_done
    result = @builder.build_release_path(@root, "v.0.8.0", "done")

    assert_equal "/path/to/.ace-taskflow/done/v.0.8.0", result
  end

  def test_build_release_path_default_status
    result = @builder.build_release_path(@root, "v.0.9.0")

    assert_equal "/path/to/.ace-taskflow/v.0.9.0", result
  end

  def test_build_ideas_path_in_backlog
    result = @builder.build_ideas_path(@root, "backlog")

    assert_equal "/path/to/.ace-taskflow/backlog/ideas", result
  end

  def test_build_ideas_path_in_release
    result = @builder.build_ideas_path(@root, "v.0.9.0")

    assert_equal "/path/to/.ace-taskflow/v.0.9.0/ideas", result
  end

  def test_extract_task_number_from_old_format
    with_config do
      path = "/path/to/.ace-taskflow/v.0.9.0/tasks/019/task.md"
      result = @builder.extract_task_number(path)

      assert_equal "019", result
    end
  end

  def test_extract_task_number_from_new_format
    with_config do
      path = "/path/to/.ace-taskflow/v.0.9.0/tasks/025-feat-idea/task.025.md"
      result = @builder.extract_task_number(path)

      assert_equal "025", result
    end
  end

  def test_extract_task_number_from_directory_path
    with_config do
      path = "/path/to/.ace-taskflow/v.0.9.0/tasks/042-fix-bug/"
      result = @builder.extract_task_number(path)

      assert_equal "042", result
    end
  end

  def test_extract_task_number_returns_nil_for_invalid_path
    with_config do
      path = "/path/to/some/random/directory"
      result = @builder.extract_task_number(path)

      assert_nil result
    end
  end

  def test_extract_release_from_path
    path = "/path/to/.ace-taskflow/v.0.9.0/tasks/001/task.md"
    result = @builder.extract_release(path)

    assert_equal "v.0.9.0", result
  end

  def test_extract_release_with_codename
    path = "/path/to/.ace-taskflow/v.1.0.0-beta/tasks/001/task.md"
    result = @builder.extract_release(path)

    assert_equal "v.1.0.0-beta", result
  end

  def test_extract_release_returns_nil_for_backlog
    path = "/path/to/.ace-taskflow/backlog/tasks/001/task.md"
    result = @builder.extract_release(path)

    assert_nil result
  end

  def test_extract_context_from_backlog_path
    path = "/path/to/.ace-taskflow/backlog/tasks/001/task.md"
    result = @builder.extract_context(path)

    assert_equal "backlog", result
  end

  def test_extract_context_from_done_path
    path = "/path/to/.ace-taskflow/done/v.0.8.0/tasks/001/task.md"
    result = @builder.extract_context(path)

    assert_equal "done", result
  end

  def test_extract_context_from_active_release_path
    path = "/path/to/.ace-taskflow/v.0.9.0/tasks/001/task.md"
    result = @builder.extract_context(path)

    assert_equal "v.0.9.0", result
  end

  def test_build_qualified_reference
    result = @builder.build_qualified_reference("v.0.9.0", "18")

    assert_equal "v.0.9.0+018", result
  end

  def test_build_qualified_reference_pads_number
    result = @builder.build_qualified_reference("backlog", 5)

    assert_equal "backlog+005", result
  end

  def test_generate_task_filename_basic
    result = @builder.generate_task_filename("Implement Dark Mode")

    assert_equal "implement-dark-mode.md", result
  end

  def test_generate_task_filename_with_special_chars
    result = @builder.generate_task_filename("Fix: Bug #123 (urgent!)")

    assert_equal "fix-bug-123-urgent.md", result
  end

  def test_generate_task_filename_truncates_long_titles
    long_title = "This is a very long task title that exceeds the maximum length limit"
    result = @builder.generate_task_filename(long_title, 30)

    assert result.length <= 33  # 30 chars + ".md"
    refute result.end_with?("-.md")
  end

  def test_generate_task_filename_collapses_multiple_hyphens
    result = @builder.generate_task_filename("Fix   multiple    spaces")

    assert_equal "fix-multiple-spaces.md", result
  end

  def test_extract_slug_from_dir_with_slug
    result = @builder.extract_slug_from_dir("025-feat-taskflow-idea")

    assert_equal "feat-taskflow-idea", result
  end

  def test_extract_slug_from_dir_without_slug
    result = @builder.extract_slug_from_dir("025")

    assert_nil result
  end

  def test_extract_slug_from_dir_old_format
    result = @builder.extract_slug_from_dir("task-025")

    assert_nil result
  end

  def test_build_task_path_handles_integer_task_number
    with_config do
      result = @builder.build_task_path(@root, "v.0.9.0", 42)

      # Integers are converted to strings without zero-padding
      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/42", result
    end
  end

  def test_build_task_path_handles_string_task_number
    with_config do
      result = @builder.build_task_path(@root, "v.0.9.0", "042")

      assert_equal "/path/to/.ace-taskflow/v.0.9.0/tasks/042", result
    end
  end
end
