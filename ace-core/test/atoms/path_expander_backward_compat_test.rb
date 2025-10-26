# frozen_string_literal: true

require "test_helper"
require "ace/core/atoms/path_expander"

class PathExpanderBackwardCompatTest < Minitest::Test
  # This test suite ensures backward compatibility with the original module API
  # All existing class methods should work exactly as before

  def setup
    @original_home = ENV['HOME']
  end

  def teardown
    ENV['HOME'] = @original_home if @original_home
  end

  # === expand() method ===

  def test_expand_expands_tilde
    ENV['HOME'] = '/home/user'

    result = Ace::Core::Atoms::PathExpander.expand("~/documents")

    assert_equal "/home/user/documents", result
  end

  def test_expand_expands_environment_variables
    ENV['TEST_VAR'] = '/test/path'

    result = Ace::Core::Atoms::PathExpander.expand("$TEST_VAR/file.txt")

    assert_equal "/test/path/file.txt", result
  ensure
    ENV.delete('TEST_VAR')
  end

  def test_expand_handles_nil
    assert_nil Ace::Core::Atoms::PathExpander.expand(nil)
  end

  def test_expand_returns_absolute_path
    result = Ace::Core::Atoms::PathExpander.expand("relative/path")

    assert Pathname.new(result).absolute?
  end

  # === join() method ===

  def test_join_combines_path_parts
    result = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")

    assert_equal "path/to/file.txt", result
  end

  def test_join_handles_empty_array
    result = Ace::Core::Atoms::PathExpander.join()

    assert_equal '', result
  end

  def test_join_handles_nil_elements
    result = Ace::Core::Atoms::PathExpander.join("path", nil, "file.txt")

    assert_equal "path/file.txt", result
  end

  def test_join_handles_nested_arrays
    result = Ace::Core::Atoms::PathExpander.join(["path", "to"], "file.txt")

    assert_equal "path/to/file.txt", result
  end

  # === dirname() method ===

  def test_dirname_returns_directory_path
    result = Ace::Core::Atoms::PathExpander.dirname("/path/to/file.txt")

    assert_equal "/path/to", result
  end

  def test_dirname_handles_nil
    assert_nil Ace::Core::Atoms::PathExpander.dirname(nil)
  end

  def test_dirname_handles_root_path
    result = Ace::Core::Atoms::PathExpander.dirname("/file.txt")

    assert_equal "/", result
  end

  # === basename() method ===

  def test_basename_returns_file_name
    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file.txt")

    assert_equal "file.txt", result
  end

  def test_basename_handles_suffix
    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file.txt", ".txt")

    assert_equal "file", result
  end

  def test_basename_handles_nil
    assert_nil Ace::Core::Atoms::PathExpander.basename(nil)
  end

  def test_basename_without_extension
    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file")

    assert_equal "file", result
  end

  # === absolute?() method ===

  def test_absolute_detects_absolute_paths
    assert Ace::Core::Atoms::PathExpander.absolute?("/absolute/path")
    assert Ace::Core::Atoms::PathExpander.absolute?("/")
  end

  def test_absolute_detects_relative_paths
    refute Ace::Core::Atoms::PathExpander.absolute?("relative/path")
    refute Ace::Core::Atoms::PathExpander.absolute?("./path")
    refute Ace::Core::Atoms::PathExpander.absolute?("../path")
  end

  def test_absolute_handles_nil
    refute Ace::Core::Atoms::PathExpander.absolute?(nil)
  end

  # === relative() method ===

  def test_relative_makes_path_relative_to_base
    result = Ace::Core::Atoms::PathExpander.relative(
      "/home/user/project/docs/file.md",
      "/home/user/project"
    )

    assert_equal "docs/file.md", result
  end

  def test_relative_handles_same_path
    result = Ace::Core::Atoms::PathExpander.relative(
      "/home/user/project",
      "/home/user/project"
    )

    assert_equal ".", result
  end

  def test_relative_handles_nil_path
    assert_nil Ace::Core::Atoms::PathExpander.relative(nil, "/base")
  end

  def test_relative_handles_nil_base
    assert_nil Ace::Core::Atoms::PathExpander.relative("/path", nil)
  end

  def test_relative_handles_different_drives_gracefully
    # On systems with different drives, should return original path
    # This is hard to test portably, but we can test the fallback behavior
    path = "/path/to/file"
    result = Ace::Core::Atoms::PathExpander.relative(path, "/other/base")

    # Should return a valid result (either relative path or original)
    assert result
  end

  # === normalize() method ===

  def test_normalize_removes_dot_segments
    result = Ace::Core::Atoms::PathExpander.normalize("/path/./to/./file.txt")

    assert_equal "/path/to/file.txt", result
  end

  def test_normalize_removes_double_dot_segments
    result = Ace::Core::Atoms::PathExpander.normalize("/path/to/../file.txt")

    assert_equal "/path/file.txt", result
  end

  def test_normalize_removes_duplicate_slashes
    result = Ace::Core::Atoms::PathExpander.normalize("/path//to///file.txt")

    assert_equal "/path/to/file.txt", result
  end

  def test_normalize_handles_nil
    assert_nil Ace::Core::Atoms::PathExpander.normalize(nil)
  end

  def test_normalize_handles_complex_paths
    result = Ace::Core::Atoms::PathExpander.normalize("/path/./to/../other/./file.txt")

    assert_equal "/path/other/file.txt", result
  end

  # === Integration: Methods work together ===

  def test_expand_and_normalize_work_together
    ENV['TEST_PATH'] = 'test/path'

    expanded = Ace::Core::Atoms::PathExpander.expand("$TEST_PATH/./file.txt")
    normalized = Ace::Core::Atoms::PathExpander.normalize(expanded)

    assert normalized.end_with?("test/path/file.txt")
    refute normalized.include?("./")
  ensure
    ENV.delete('TEST_PATH')
  end

  def test_join_and_dirname_work_together
    joined = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")
    dir = Ace::Core::Atoms::PathExpander.dirname(joined)

    assert_equal "path/to", dir
  end

  def test_join_and_basename_work_together
    joined = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")
    base = Ace::Core::Atoms::PathExpander.basename(joined)

    assert_equal "file.txt", base
  end

  # === Class method API unchanged ===

  def test_class_methods_callable_without_instance
    # All these should work without creating an instance
    # (No exception should be raised)
    Ace::Core::Atoms::PathExpander.expand("~/path")
    Ace::Core::Atoms::PathExpander.join("a", "b")
    Ace::Core::Atoms::PathExpander.dirname("/path/file")
    Ace::Core::Atoms::PathExpander.basename("/path/file")
    Ace::Core::Atoms::PathExpander.absolute?("/path")
    Ace::Core::Atoms::PathExpander.relative("/a", "/b")
    Ace::Core::Atoms::PathExpander.normalize("/path/./file")
    Ace::Core::Atoms::PathExpander.protocol?("wfi://test")

    # If we got here, all methods were callable
    assert true
  end

  def test_old_module_usage_pattern_still_works
    # Test that the old pattern of calling methods still works
    expander = Ace::Core::Atoms::PathExpander

    result = expander.expand("~/docs")
    assert result.end_with?("/docs")

    result = expander.join("a", "b", "c")
    assert_equal "a/b/c", result

    result = expander.absolute?("/absolute")
    assert result
  end
end
