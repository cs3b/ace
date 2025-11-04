# frozen_string_literal: true

require "test_helper"
require "fileutils"

class PathExpanderTest < Minitest::Test
  include TestHelper

  def setup
    @expander = Ace::Git::Worktree::Atoms::PathExpander
    @temp_dir = Dir.mktmpdir("ace-git-worktree-test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  def test_expand_home_directory
    slug = @expander.expand("~")
    assert_equal Dir.home, slug
  end

  def test_expand_relative_path
    FileUtils.mkdir_p("test/dir")
    slug = @expander.expand("./test/dir")
    assert_equal File.expand_path("test/dir"), slug
  end

  def test_expand_absolute_path
    slug = @expander.expand("/tmp/test")
    assert_equal "/tmp/test", slug
  end

  def test_expand_empty_string
    slug = @expander.expand("")
    assert_equal "", slug
  end

  def test_expand_nil
    slug = @expander.expand(nil)
    assert_equal "", slug
  end

  def test_expand_with_user_name
    # This test might fail if the user doesn't exist
    # We'll skip it if the user lookup fails
    begin
      Dir.home("root")
      slug = @expander.expand("~root")
      # Don't assert exact value since it depends on system
      assert slug.is_a?(String)
    rescue ArgumentError
      skip "User ~root not found on this system"
    end
  end

  def test_resolve_relative_to_base
    base = File.expand_path("base")
    slug = @expander.resolve("subdir", base)
    assert_equal File.expand_path("base/subdir"), slug
  end

  def test_resolve_absolute_path
    slug = @expander.resolve("/absolute/path", "base/irrelevant")
    assert_equal "/absolute/path", slug
  end

  def test_writable_existing_directory
    test_dir = File.join(@temp_dir, "writable_test")
    FileUtils.mkdir_p(test_dir)

    assert @expander.writable?(test_dir)
  end

  def test_writable_nonexistent_directory
    test_dir = File.join(@temp_dir, "nonexistent")

    assert @expander.writable?(test_dir, create_if_missing: false)
    refute File.exist?(test_dir)
  end

  def test_writable_create_if_missing
    test_dir = File.join(@temp_dir, "created")

    assert @expander.writable?(test_dir, create_if_missing: true)
    assert File.exist?(test_dir)
    assert File.directory?(test_dir)
  end

  def test_writable_permission_denied
    # Create a directory and remove write permissions
    test_dir = File.join(@temp_dir, "readonly")
    FileUtils.mkdir_p(test_dir)

    # Make directory read-only (this might not work on all systems)
    begin
      File.chmod(0555, test_dir)

      # Test should fail due to permissions
      refute @expander.writable?(File.join(test_dir, "subdir"), create_if_missing: true)
    rescue Errno::EPERM
      # Expected on some systems
    ensure
      # Restore permissions for cleanup
      File.chmod(0755, test_dir) rescue nil
    end
  end

  def test_validate_for_worktree_valid_path
    test_path = File.join(@temp_dir, "valid_worktree")
    FileUtils.mkdir_p(test_path)

    validation = @expander.validate_for_worktree(test_path, @temp_dir)
    assert validation[:valid]
    assert_nil validation[:error]
    assert_equal test_path, validation[:expanded_path]
  end

  def test_validate_for_worktree_nonexistent_parent
    nonexistent = File.join(@temp_dir, "nonexistent", "worktree")

    validation = @expander.validate_for_worktree(nonexistent, @temp_dir)
    refute validation[:valid]
    assert_match(/Parent directory does not exist/, validation[:error])
  end

  def test_validate_for_worktree_in_git_repo
    # Create a worktree path inside the git repo (should be invalid)
    git_repo_path = @temp_dir
    worktree_in_repo = File.join(git_repo_path, "worktree_in_repo")

    validation = @expander.validate_for_worktree(worktree_in_repo, git_repo_path)
    refute validation[:valid]
    assert_match(/cannot be within the git repository/, validation[:error])
  end

  def test_validate_for_worktree_long_path
    # Create a very long path
    long_name = "a" * 5000
    long_path = File.join(@temp_dir, long_name)

    validation = @expander.validate_for_worktree(long_path, @temp_dir)
    refute validation[:valid]
    assert_match(/too long/, validation[:error])
  end

  def test_validate_for_worktree_existing_file
    # Create a file where we want a directory
    test_file = File.join(@temp_dir, "existing_file")
    File.write(test_file, "test content")

    validation = @expander.validate_for_worktree(test_file, @temp_dir)
    refute validation[:valid]
    assert_match(/exists but is a file/, validation[:error])
  end

  def test_validate_for_worktree_existing_nonempty_directory
    # Create a directory with content
    test_dir = File.join(@temp_dir, "existing_dir")
    FileUtils.mkdir_p(test_dir)
    File.write(File.join(test_dir, "content.txt"), "test")

    validation = @expander.validate_for_worktree(test_dir, @temp_dir)
    refute validation[:valid]
    assert_match(/already exists and is not empty/, validation[:error])
  end

  def test_relative_to_git_root
    git_root = @temp_dir
    worktree_path = File.join(git_root, ".ace-wt", "task.081")

    relative = @expander.relative_to_git_root(worktree_path, git_root)
    assert_equal ".ace-wt/task.081", relative
  end

  def test_relative_to_git_root_outside_repo
    git_root = @temp_dir
    outside_path = File.join(@temp_dir, "..", "outside")

    relative = @expander.relative_to_git_root(outside_path, git_root)
    assert_equal outside_path, relative
  end

  def test_expand_tilde_with_slash
    slug = @expander.expand("~/")
    assert_equal Dir.home, slug
  end

  def test_expand_tilde_with_subdirectory
    subdir = File.join(Dir.home, "test_subdir")
    FileUtils.mkdir_p(subdir)

    slug = @expander.expand("~/test_subdir")
    assert_equal subdir, slug
  end

  def test_expand_multiple_slashes
    slug = @expander.expand("///multiple///slashes")
    # Should normalize to a single path
    assert slug.end_with?("multiple/slashes")
  end

  def test_expand_current_directory
    slug = @expander.expand(".")
    assert_equal Dir.pwd, slug
  end

  def test_expand_parent_directory
    parent = File.dirname(Dir.pwd)
    slug = @expander.expand("..")
    assert_equal parent, slug
  end
end