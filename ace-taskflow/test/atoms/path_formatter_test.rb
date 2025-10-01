# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/atoms/path_formatter"

class PathFormatterTest < AceTaskflowTestCase
  def setup
    @formatter = Ace::Taskflow::Atoms::PathFormatter
    @root = "/Users/developer/projects/myapp"
  end

  def test_format_relative_path_removes_root
    absolute = "/Users/developer/projects/myapp/.ace-taskflow/v.0.9.0/t/001/task.md"
    result = @formatter.format_relative_path(absolute, @root)

    assert_equal ".ace-taskflow/v.0.9.0/t/001/task.md", result
  end

  def test_format_relative_path_with_nil_root_uses_pwd
    absolute = "#{Dir.pwd}/file.txt"
    result = @formatter.format_relative_path(absolute, nil)

    assert_equal "file.txt", result
  end

  def test_format_relative_path_handles_already_relative
    relative = "docs/README.md"
    result = @formatter.format_relative_path(relative, @root)

    assert_equal "docs/README.md", result
  end

  def test_format_relative_path_with_empty_path
    result = @formatter.format_relative_path("", @root)

    assert_equal "", result
  end

  def test_format_relative_path_with_nil_path
    result = @formatter.format_relative_path(nil, @root)

    assert_equal "", result
  end

  def test_format_relative_path_preserves_path_outside_root
    absolute = "/Users/other/project/file.md"
    result = @formatter.format_relative_path(absolute, @root)

    assert_equal "/Users/other/project/file.md", result
  end

  def test_format_display_path_short_enough
    path = "/Users/developer/projects/myapp/docs/README.md"
    result = @formatter.format_display_path(path, @root, max_length: 70)

    assert_equal "docs/README.md", result
  end

  def test_format_display_path_truncates_long_path
    long_path = "/Users/developer/projects/myapp/very/long/path/to/some/deeply/nested/directory/file.md"
    result = @formatter.format_display_path(long_path, @root, max_length: 30)

    assert result.length <= 30
    assert result.include?("...")
  end

  def test_format_display_path_smart_truncation_for_ace_taskflow
    path = "/Users/developer/projects/myapp/.ace-taskflow/v.0.9.0/t/025-feat-idea/task.025.md"
    # Relative path is 49 chars, so use max_length: 45 to trigger truncation
    result = @formatter.format_display_path(path, @root, max_length: 45)

    # Should keep the important parts
    assert result.include?(".ace-taskflow")
    assert result.include?("task.025.md")
    assert result.include?("...")
  end

  def test_format_display_path_preserves_short_ace_taskflow_paths
    path = "/Users/developer/projects/myapp/.ace-taskflow/v.0.9.0/task.md"
    result = @formatter.format_display_path(path, @root, max_length: 70)

    assert_equal ".ace-taskflow/v.0.9.0/task.md", result
  end

  def test_format_display_path_handles_default_max_length
    path = "/Users/developer/projects/myapp/some/path/file.md"
    result = @formatter.format_display_path(path, @root)

    refute_nil result
    assert result.length <= 70
  end

  def test_format_display_path_with_very_short_max_length
    path = "/Users/developer/projects/myapp/.ace-taskflow/v.0.9.0/t/001/task.md"
    result = @formatter.format_display_path(path, @root, max_length: 20)

    assert result.length <= 20
    assert result.include?("...")
  end

  def test_format_relative_path_with_special_characters
    absolute = "/Users/developer/projects/myapp/tasks (urgent)/task #1.md"
    result = @formatter.format_relative_path(absolute, @root)

    assert_equal "tasks (urgent)/task #1.md", result
  end

  def test_format_display_path_preserves_structure_for_ace_taskflow
    path = "/Users/developer/projects/myapp/.ace-taskflow/backlog/v.1.0.0/t/042/task.md"
    result = @formatter.format_display_path(path, @root, max_length: 100)

    assert_equal ".ace-taskflow/backlog/v.1.0.0/t/042/task.md", result
  end

  def test_format_display_path_truncation_symmetry
    path = "/Users/developer/projects/myapp/very/long/unnecessary/path/structure/document.md"
    result = @formatter.format_display_path(path, @root, max_length: 30)

    # Should have roughly equal parts on both sides of "..."
    parts = result.split("...")
    assert_equal 2, parts.length
    assert (parts[0].length - parts[1].length).abs <= 2
  end
end
