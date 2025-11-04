# frozen_string_literal: true

require "test_helper"
require "fileutils"

class PathExpanderTest < AceGitWorktreeTestCase
  def setup
    @expander = Ace::Git::Worktree::Atoms::PathExpander
  end

  def test_expand_with_absolute_path
    absolute = "/usr/local/bin"
    assert_equal absolute, @expander.expand(absolute)
  end

  def test_expand_with_home_directory
    home_path = "~/Documents"
    expanded = @expander.expand(home_path)

    assert expanded.start_with?(ENV["HOME"])
    assert expanded.end_with?("Documents")
  end

  def test_expand_with_relative_path
    with_temp_dir do |dir|
      relative = "./subdir"
      expanded = @expander.expand(relative, base: dir)

      assert_equal File.join(dir, "subdir"), expanded
    end
  end

  def test_expand_with_parent_directory
    with_temp_dir do |dir|
      Dir.mkdir("subdir")
      Dir.chdir("subdir") do
        expanded = @expander.expand("../file.txt")
        assert_equal File.join(dir, "file.txt"), expanded
      end
    end
  end

  def test_expand_returns_nil_for_nil_input
    assert_nil @expander.expand(nil)
  end

  def test_expand_returns_nil_for_empty_string
    assert_nil @expander.expand("")
  end

  def test_safe_validates_path_within_root
    with_temp_dir do |dir|
      safe_path = File.join(dir, "subdir", "file.txt")
      assert @expander.safe?(safe_path, allowed_root: dir)

      unsafe_path = "/etc/passwd"
      refute @expander.safe?(unsafe_path, allowed_root: dir)
    end
  end

  def test_safe_returns_false_for_nil_inputs
    refute @expander.safe?(nil, allowed_root: "/tmp")
    refute @expander.safe?("/tmp/file", allowed_root: nil)
  end

  def test_relative_creates_relative_path
    base = "/home/user/project"
    full = "/home/user/project/lib/file.rb"

    assert_equal "lib/file.rb", @expander.relative(full, base: base)
  end

  def test_relative_returns_nil_for_nil_input
    assert_nil @expander.relative(nil)
  end

  def test_join_combines_path_components
    assert_equal "path/to/file.txt", @expander.join("path", "to", "file.txt")
    assert_equal "path/file.txt", @expander.join("path", nil, "file.txt")
    assert_equal "path/file.txt", @expander.join("path", "", "file.txt")
  end

  def test_join_returns_empty_for_all_nil_or_empty
    assert_equal "", @expander.join(nil, "", nil)
  end

  def test_directory_checks_if_path_is_directory
    with_temp_dir do |dir|
      Dir.mkdir("testdir")
      File.write("testfile", "content")

      assert @expander.directory?("testdir")
      assert @expander.directory?(dir)
      refute @expander.directory?("testfile")
      refute @expander.directory?("nonexistent")
    end
  end

  def test_directory_returns_false_for_nil_or_empty
    refute @expander.directory?(nil)
    refute @expander.directory?("")
  end

  def test_file_checks_if_path_is_file
    with_temp_dir do
      Dir.mkdir("testdir")
      File.write("testfile", "content")

      assert @expander.file?("testfile")
      refute @expander.file?("testdir")
      refute @expander.file?("nonexistent")
    end
  end

  def test_file_returns_false_for_nil_or_empty
    refute @expander.file?(nil)
    refute @expander.file?("")
  end

  def test_ensure_directory_creates_directory
    with_temp_dir do
      path = "new/nested/directory"

      refute Dir.exist?(path)
      assert @expander.ensure_directory(path)
      assert Dir.exist?(path)

      # Should return true for existing directory
      assert @expander.ensure_directory(path)
    end
  end

  def test_ensure_directory_returns_false_for_nil_or_empty
    refute @expander.ensure_directory(nil)
    refute @expander.ensure_directory("")
  end

  def test_parent_returns_parent_directory
    assert_equal "/home/user", @expander.parent("/home/user/file.txt")
    assert_equal "/", @expander.parent("/file.txt")
  end

  def test_parent_returns_nil_for_nil_or_empty
    assert_nil @expander.parent(nil)
    assert_nil @expander.parent("")
  end

  def test_basename_returns_base_name
    assert_equal "file.txt", @expander.basename("/home/user/file.txt")
    assert_equal "file.txt", @expander.basename("file.txt")
  end

  def test_basename_returns_nil_for_nil_or_empty
    assert_nil @expander.basename(nil)
    assert_nil @expander.basename("")
  end
end