# frozen_string_literal: true

require_relative "../test_helper"
require "minitest/mock"

class PathResolverTest < TestCase
  def setup
    @mock_git = Minitest::Mock.new
    @resolver = Ace::GitCommit::Molecules::PathResolver.new(@mock_git)
  end

  def test_files_in_path_returns_tracked_files
    @mock_git.expect :execute, "file1.txt\nfile2.txt\n", ["ls-files", "lib/"]

    files = @resolver.files_in_path("lib/")

    assert_equal ["file1.txt", "file2.txt"], files
    @mock_git.verify
  end

  def test_files_in_path_returns_empty_for_empty_path
    @mock_git.expect :execute, "", ["ls-files", "empty/"]

    files = @resolver.files_in_path("empty/")

    assert_empty files
    @mock_git.verify
  end

  def test_files_in_path_handles_git_error
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "fatal: not a git repository"
    end

    files = @resolver.files_in_path("path/")

    assert_empty files
    assert_match(/not a git repository/, @resolver.last_error)
    @mock_git.verify
  end

  def test_filter_by_paths_filters_files
    all_files = ["lib/file1.rb", "test/file2.rb", "README.md"]
    allowed_paths = ["lib/"]

    # Mock File.expand_path for path matching
    File.stub :expand_path, ->(path) { path } do
      File.stub :file?, ->(path) { false } do
        filtered = @resolver.filter_by_paths(all_files, allowed_paths)
        assert_equal ["lib/file1.rb"], filtered
      end
    end
  end

  def test_filter_by_paths_returns_all_when_no_paths
    all_files = ["lib/file1.rb", "test/file2.rb"]

    filtered = @resolver.filter_by_paths(all_files, [])

    assert_equal all_files, filtered
  end

  def test_filter_by_paths_with_multiple_paths
    all_files = ["lib/file1.rb", "test/file2.rb", "docs/file3.md"]
    allowed_paths = ["lib/", "test/"]

    File.stub :expand_path, ->(path) { path } do
      File.stub :file?, ->(path) { false } do
        filtered = @resolver.filter_by_paths(all_files, allowed_paths)
        assert_equal ["lib/file1.rb", "test/file2.rb"], filtered
      end
    end
  end

  def test_modified_files_in_paths_finds_unstaged_changes
    @mock_git.expect :execute, "lib/file1.rb\n", ["diff", "--name-only", "lib/"]

    files = @resolver.modified_files_in_paths(["lib/"], staged: false)

    assert_equal ["lib/file1.rb"], files
    @mock_git.verify
  end

  def test_modified_files_in_paths_finds_staged_changes
    @mock_git.expect :execute, "lib/file1.rb\n", ["diff", "--name-only", "--cached", "lib/"]

    files = @resolver.modified_files_in_paths(["lib/"], staged: true)

    assert_equal ["lib/file1.rb"], files
    @mock_git.verify
  end

  def test_modified_files_in_paths_with_multiple_paths
    @mock_git.expect :execute, "lib/file1.rb\n", ["diff", "--name-only", "lib/"]
    @mock_git.expect :execute, "test/file2.rb\n", ["diff", "--name-only", "test/"]

    files = @resolver.modified_files_in_paths(["lib/", "test/"], staged: false)

    assert_equal ["lib/file1.rb", "test/file2.rb"], files
    @mock_git.verify
  end

  def test_modified_files_in_paths_returns_empty_for_empty_paths
    files = @resolver.modified_files_in_paths([], staged: false)

    assert_empty files
  end

  def test_modified_files_in_paths_handles_git_error
    @mock_git.expect :execute, nil do |*args|
      raise Ace::GitCommit::GitError, "error"
    end

    files = @resolver.modified_files_in_paths(["lib/"], staged: false)

    assert_empty files
    assert @resolver.last_error
    @mock_git.verify
  end

  def test_validate_paths_separates_valid_and_invalid
    # Use stub instead of testing real filesystem
    File.stub :exist?, ->(path) { path == "valid_path" } do
      # Mock git status to return empty (no changes for invalid_path)
      @mock_git.expect :execute, "", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["valid_path", "invalid_path"])

      assert_equal ["valid_path"], result[:valid]
      assert_equal ["invalid_path"], result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_handles_empty_array
    result = @resolver.validate_paths([])

    assert_empty result[:valid]
    assert_empty result[:invalid]
  end

  def test_all_paths_exist_returns_true_when_all_exist
    File.stub :exist?, ->(path) { true } do
      assert @resolver.all_paths_exist?(["path1", "path2"])
    end
  end

  def test_all_paths_exist_returns_false_when_some_missing
    File.stub :exist?, ->(path) { path == "path1" } do
      # Mock git status to return empty (no changes for path2)
      @mock_git.expect :execute, "", ["status", "--porcelain", "-z"]

      refute @resolver.all_paths_exist?(["path1", "path2"])
      @mock_git.verify
    end
  end

  def test_all_paths_exist_returns_true_for_empty_array
    assert @resolver.all_paths_exist?([])
  end

  def test_resolve_paths_expands_directories
    paths = ["lib/"]

    File.stub :directory?, ->(path) { path == "lib/" } do
      File.stub :exist?, ->(path) { true } do
        @mock_git.expect :execute, "lib/file1.rb\nlib/file2.rb\n", ["ls-files", "lib/"]

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file1.rb", "lib/file2.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_includes_single_files
    paths = ["README.md"]

    File.stub :directory?, ->(path) { false } do
      File.stub :exist?, ->(path) { true } do
        resolved = @resolver.resolve_paths(paths)

        assert_equal ["README.md"], resolved
      end
    end
  end

  def test_resolve_paths_handles_mixed_paths
    paths = ["lib/", "README.md"]

    File.stub :directory?, ->(path) { path == "lib/" } do
      File.stub :exist?, ->(path) { true } do
        @mock_git.expect :execute, "lib/file1.rb\n", ["ls-files", "lib/"]

        resolved = @resolver.resolve_paths(paths)

        assert_includes resolved, "lib/file1.rb"
        assert_includes resolved, "README.md"
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_returns_sorted_unique
    paths = ["lib/", "lib/"]

    File.stub :directory?, ->(path) { path == "lib/" } do
      File.stub :exist?, ->(path) { true } do
        @mock_git.expect :execute, "lib/file2.rb\nlib/file1.rb\n", ["ls-files", "lib/"]
        @mock_git.expect :execute, "lib/file2.rb\nlib/file1.rb\n", ["ls-files", "lib/"]

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file1.rb", "lib/file2.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_returns_empty_for_empty_input
    assert_empty @resolver.resolve_paths([])
    assert_empty @resolver.resolve_paths(nil)
  end

  def test_resolve_paths_includes_nonexistent_paths_for_validation
    paths = ["nonexistent/"]

    File.stub :directory?, ->(path) { false } do
      File.stub :exist?, ->(path) { false } do
        resolved = @resolver.resolve_paths(paths)

        assert_equal ["nonexistent/"], resolved
      end
    end
  end

  # Tests for glob pattern support
  def test_resolve_paths_expands_glob_pattern
    paths = ["**/*.rb"]

    # Mock Dir.glob to return filesystem matches
    Dir.stub :glob, ["lib/file1.rb", "test/file2.rb"] do
      File.stub :file?, ->(path) { true } do
        # Mock git ls-files to return tracked files
        @mock_git.expect :execute, "lib/file1.rb\ntest/file2.rb\n", ["ls-files"]
        # Mock untracked files (empty in this case)
        @mock_git.expect :execute, "", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file1.rb", "test/file2.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_filters_glob_to_committable_files_only
    paths = ["lib/*.rb"]

    # Dir.glob returns files including gitignored
    Dir.stub :glob, ["lib/tracked.rb", "lib/untracked.rb", "lib/ignored.rb"] do
      File.stub :file?, ->(path) { true } do
        # Git ls-files returns tracked files
        @mock_git.expect :execute, "lib/tracked.rb\n", ["ls-files"]
        # Git ls-files --others returns untracked but NOT ignored
        @mock_git.expect :execute, "lib/untracked.rb\n", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        # Should include tracked AND untracked, but NOT gitignored
        assert_equal ["lib/tracked.rb", "lib/untracked.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_handles_multiple_glob_patterns
    paths = ["lib/*.rb", "test/*.rb"]

    Dir.stub :glob, ->(pattern, *) do
      case pattern
      when "lib/*.rb"
        ["lib/file1.rb"]
      when "test/*.rb"
        ["test/file2.rb"]
      else
        []
      end
    end do
      File.stub :file?, ->(path) { true } do
        # With caching, git ls-files is called once and result is cached
        @mock_git.expect :execute, "lib/file1.rb\ntest/file2.rb\n", ["ls-files"]
        # Mock untracked files (empty in this case)
        @mock_git.expect :execute, "", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file1.rb", "test/file2.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_handles_glob_with_no_matches
    paths = ["nonexistent/**/*.xyz"]

    Dir.stub :glob, [] do
      @mock_git.expect :execute, "", ["ls-files"]
      @mock_git.expect :execute, "", ["ls-files", "--others", "--exclude-standard"]

      resolved = @resolver.resolve_paths(paths)

      assert_empty resolved
      @mock_git.verify
    end
  end

  def test_resolve_paths_excludes_directories_from_glob
    paths = ["lib/*"]

    # Dir.glob returns both files and directories
    Dir.stub :glob, ["lib/file.rb", "lib/subdir"] do
      File.stub :file?, ->(path) { path == "lib/file.rb" } do
        @mock_git.expect :execute, "lib/file.rb\n", ["ls-files"]
        @mock_git.expect :execute, "", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_handles_mixed_paths_and_globs
    paths = ["README.md", "lib/*.rb", "test/"]

    # Handle README.md as regular file
    # Handle lib/*.rb as glob
    # Handle test/ as directory
    File.stub :directory?, ->(path) { path == "test/" } do
      File.stub :exist?, ->(path) { path == "README.md" } do
        Dir.stub :glob, ->(pattern, *) do
          (pattern == "lib/*.rb") ? ["lib/file1.rb"] : []
        end do
          File.stub :file?, ->(path) { true } do
            @mock_git.expect :execute, "lib/file1.rb\n", ["ls-files"]
            @mock_git.expect :execute, "", ["ls-files", "--others", "--exclude-standard"]
            @mock_git.expect :execute, "test/helper.rb\n", ["ls-files", "test/"]

            resolved = @resolver.resolve_paths(paths)

            assert_includes resolved, "README.md"
            assert_includes resolved, "lib/file1.rb"
            assert_includes resolved, "test/helper.rb"
            @mock_git.verify
          end
        end
      end
    end
  end

  def test_resolve_paths_handles_glob_errors_gracefully
    paths = ["lib/*.rb"]

    # Simulate Dir.glob raising an error
    Dir.stub :glob, ->(*) { raise StandardError, "Permission denied" } do
      resolved = @resolver.resolve_paths(paths)

      assert_empty resolved
      assert_match(/Permission denied/, @resolver.last_error)
    end
  end

  # Tests for glob expansion including untracked files
  def test_resolve_paths_includes_untracked_files_in_glob
    paths = ["*.rb"]

    # Dir.glob returns both tracked and untracked files
    Dir.stub :glob, ["tracked.rb", "untracked.rb"] do
      File.stub :file?, ->(path) { true } do
        # Git ls-files returns only tracked files
        @mock_git.expect :execute, "tracked.rb\n", ["ls-files"]
        # Git ls-files --others returns untracked files
        @mock_git.expect :execute, "untracked.rb\n", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        # Should include both tracked AND untracked
        assert_equal ["tracked.rb", "untracked.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_excludes_gitignored_files_from_glob
    paths = ["*.rb"]

    # Dir.glob returns tracked, untracked, and gitignored files
    Dir.stub :glob, ["tracked.rb", "untracked.rb", "ignored.rb"] do
      File.stub :file?, ->(path) { true } do
        # Git ls-files returns tracked files
        @mock_git.expect :execute, "tracked.rb\n", ["ls-files"]
        # Git ls-files --others --exclude-standard does NOT return ignored.rb
        @mock_git.expect :execute, "untracked.rb\n", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        # Should include tracked and untracked but NOT gitignored
        assert_includes resolved, "tracked.rb"
        assert_includes resolved, "untracked.rb"
        refute_includes resolved, "ignored.rb"
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_glob_with_only_untracked_files
    paths = ["*.rb"]

    # Scenario: New project, no tracked files yet, only untracked
    Dir.stub :glob, ["new_file.rb"] do
      File.stub :file?, ->(path) { true } do
        # No tracked files
        @mock_git.expect :execute, "", ["ls-files"]
        # One untracked file
        @mock_git.expect :execute, "new_file.rb\n", ["ls-files", "--others", "--exclude-standard"]

        resolved = @resolver.resolve_paths(paths)

        # Should include the untracked file
        assert_equal ["new_file.rb"], resolved
        @mock_git.verify
      end
    end
  end

  # Tests for glob_pattern? (now public)
  def test_glob_pattern_detects_asterisk
    assert @resolver.glob_pattern?("**/*.rb")
    assert @resolver.glob_pattern?("lib/*.txt")
  end

  def test_glob_pattern_detects_question_mark
    assert @resolver.glob_pattern?("file?.txt")
  end

  def test_glob_pattern_detects_brackets
    assert @resolver.glob_pattern?("file[123].txt")
  end

  def test_glob_pattern_detects_braces
    assert @resolver.glob_pattern?("file{a,b}.txt")
  end

  def test_glob_pattern_returns_false_for_regular_paths
    refute @resolver.glob_pattern?("lib/file.rb")
    refute @resolver.glob_pattern?("README.md")
    refute @resolver.glob_pattern?("path/to/directory/")
  end

  # Tests for simple_glob_pattern?
  def test_simple_glob_pattern_detects_non_recursive_globs
    assert @resolver.simple_glob_pattern?("*.rb")
    assert @resolver.simple_glob_pattern?("lib/*.txt")
    assert @resolver.simple_glob_pattern?("file?.rb")
    assert @resolver.simple_glob_pattern?("file[123].txt")
  end

  def test_simple_glob_pattern_returns_false_for_recursive_globs
    refute @resolver.simple_glob_pattern?("**/*.rb")
    refute @resolver.simple_glob_pattern?("lib/**/*.txt")
  end

  def test_simple_glob_pattern_returns_false_for_regular_paths
    refute @resolver.simple_glob_pattern?("lib/file.rb")
    refute @resolver.simple_glob_pattern?("README.md")
  end

  # Tests for suggest_recursive_pattern
  def test_suggest_recursive_pattern_for_simple_glob
    assert_equal "**/*.rb", @resolver.suggest_recursive_pattern("*.rb")
    assert_equal "**/*.txt", @resolver.suggest_recursive_pattern("*.txt")
  end

  def test_suggest_recursive_pattern_handles_subdirectory_patterns
    # Patterns like "lib/*.rb" should suggest "lib/**/*.rb"
    assert_equal "lib/**/*.rb", @resolver.suggest_recursive_pattern("lib/*.rb")
    assert_equal "src/components/**/*.tsx", @resolver.suggest_recursive_pattern("src/components/*.tsx")
  end

  def test_suggest_recursive_pattern_returns_nil_for_already_recursive
    assert_nil @resolver.suggest_recursive_pattern("**/*.rb")
  end

  def test_suggest_recursive_pattern_returns_nil_for_regular_paths
    assert_nil @resolver.suggest_recursive_pattern("lib/file.rb")
  end

  # Tests for within_repository?
  def test_within_repository_returns_true_for_paths_in_repo
    File.stub :exist?, ->(path) { true } do
      File.stub :expand_path, ->(path) {
        # Handle both the file path and repo root
        (path == "/repo") ? "/repo" : "/repo/#{path}"
      } do
        @mock_git.expect :execute, "/repo\n", ["rev-parse", "--show-toplevel"]

        assert @resolver.within_repository?("lib/file.rb")
        @mock_git.verify
      end
    end
  end

  def test_within_repository_returns_false_for_nonexistent_paths
    File.stub :exist?, ->(path) { false } do
      refute @resolver.within_repository?("nonexistent/path")
    end
  end

  def test_within_repository_returns_false_for_paths_outside_repo
    File.stub :exist?, ->(path) { true } do
      File.stub :expand_path, ->(path) {
        path.start_with?("/other") ? "/other/#{path}" : "/repo/#{path}"
      } do
        @mock_git.expect :execute, "/repo\n", ["rev-parse", "--show-toplevel"]

        refute @resolver.within_repository?("/other/file.rb")
        @mock_git.verify
      end
    end
  end

  def test_within_repository_handles_git_error
    File.stub :exist?, ->(path) { true } do
      File.stub :expand_path, ->(path) { "/repo/#{path}" } do
        @mock_git.expect :execute, nil do |*args|
          raise Ace::GitCommit::GitError, "not a git repository"
        end

        refute @resolver.within_repository?("lib/file.rb")
        assert_match(/not a git repository/, @resolver.last_error)
        @mock_git.verify
      end
    end
  end

  # Tests for deleted/renamed file handling in validate_paths
  def test_validate_paths_accepts_deleted_files
    # File doesn't exist on disk, but has git status D (deleted)
    # Using -z format: NUL-terminated entries
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D deleted_file.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["deleted_file.txt"])

      assert_equal ["deleted_file.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_accepts_directory_with_deleted_files
    # Directory path that contains deleted files
    # Using -z format: multiple NUL-terminated entries
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D scripts/old_script.sh\0 D scripts/another.sh\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["scripts/"])

      assert_equal ["scripts/"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_accepts_renamed_file_old_path
    # Old path from a rename doesn't exist, but shows in git status as rename
    # Using -z format: R  old_path\0new_path\0
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "R  old_name.txt\0new_name.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["old_name.txt"])

      assert_equal ["old_name.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_accepts_copied_file
    # Copied file shows C status with old and new paths
    # Using -z format: C  original.txt\0copied.txt\0
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "C  original.txt\0copied.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["copied.txt"])

      assert_equal ["copied.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_accepts_copied_file_original_path
    # Original path from a copy operation
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "C  original.txt\0copied.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["original.txt"])

      assert_equal ["original.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_rejects_truly_nonexistent_paths
    # Path doesn't exist and has no git status
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["truly_nonexistent.txt"])

      assert_empty result[:valid]
      assert_equal ["truly_nonexistent.txt"], result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_handles_mixed_existing_and_deleted
    # Mix of existing files and deleted files
    File.stub :exist?, ->(path) { path == "existing.txt" } do
      @mock_git.expect :execute, " D deleted.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["existing.txt", "deleted.txt", "nonexistent.txt"])

      assert_equal ["existing.txt", "deleted.txt"], result[:valid]
      assert_equal ["nonexistent.txt"], result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_skips_git_check_when_all_exist
    # When all files exist, no git status call should be made
    # Explicitly verify git is NOT called by failing if it is
    File.stub :exist?, ->(path) { true } do
      @mock_git.expect :execute, nil do |*_args|
        raise "Git should not be called when all files exist!"
      end

      result = @resolver.validate_paths(["file1.txt", "file2.txt"])

      assert_equal ["file1.txt", "file2.txt"], result[:valid]
      assert_empty result[:invalid]
      # Note: @mock_git.verify is intentionally NOT called since git should not be invoked
    end
  end

  def test_validate_paths_handles_git_error_gracefully
    # Git error should result in paths being marked as invalid
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, nil do |*args|
        raise Ace::GitCommit::GitError, "not a git repository"
      end

      result = @resolver.validate_paths(["some_file.txt"])

      assert_empty result[:valid]
      assert_equal ["some_file.txt"], result[:invalid]
      @mock_git.verify
    end
  end

  def test_all_paths_exist_returns_true_for_deleted_files
    # all_paths_exist? should return true for deleted files with git status
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D deleted.txt\0", ["status", "--porcelain", "-z"]

      assert @resolver.all_paths_exist?(["deleted.txt"])
      @mock_git.verify
    end
  end

  # Path normalization tests
  def test_validate_paths_normalizes_dot_slash_prefix
    # ./deleted.txt should match deleted.txt from git status
    # No rev-parse needed - ./ is simply stripped
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D deleted.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["./deleted.txt"])

      assert_equal ["./deleted.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_normalizes_absolute_path
    # Absolute path should match repo-relative path from git status
    File.stub :exist?, ->(path) { false } do
      # Order matters: status is called first, then rev-parse during normalization
      @mock_git.expect :execute, " D deleted.txt\0", ["status", "--porcelain", "-z"]
      @mock_git.expect :execute, "/path/to/repo", ["rev-parse", "--show-toplevel"]

      result = @resolver.validate_paths(["/path/to/repo/deleted.txt"])

      assert_equal ["/path/to/repo/deleted.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_normalizes_trailing_slash
    # Trailing slash should be stripped for comparison
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D some_dir\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["some_dir/"])

      assert_equal ["some_dir/"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_normalizes_renamed_file_with_dot_prefix
    # ./new_name.txt should match renamed file in git status
    # Using -z format: R  old_path\0new_path\0
    # No rev-parse needed - ./ is simply stripped
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "R  old_name.txt\0new_name.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["./new_name.txt"])

      assert_equal ["./new_name.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  # -z format tests (paths with spaces don't need quoting with -z)
  def test_validate_paths_handles_path_with_spaces
    # With -z flag, paths with spaces are NOT quoted
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D my file.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["my file.txt"])

      assert_equal ["my file.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_handles_renamed_paths_with_spaces
    # Renamed files with spaces in -z format
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, "R  old name.txt\0new name.txt\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["new name.txt"])

      assert_equal ["new name.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  # Directory matching tests
  def test_validate_paths_accepts_directory_with_changed_files
    # Directory doesn't exist but contains files with git changes
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " M dir/file1.rb\0 M dir/file2.rb\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["dir/"])

      assert_equal ["dir/"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  def test_validate_paths_directory_without_trailing_slash
    # Directory without trailing slash should still match
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " M mydir/file.rb\0", ["status", "--porcelain", "-z"]

      result = @resolver.validate_paths(["mydir"])

      assert_equal ["mydir"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end

  # Repo root memoization test
  def test_validate_paths_memoizes_repo_root_for_multiple_absolute_paths
    # Multiple absolute paths should only call rev-parse once
    File.stub :exist?, ->(path) { false } do
      @mock_git.expect :execute, " D file1.txt\0 D file2.txt\0", ["status", "--porcelain", "-z"]
      # Only one rev-parse call expected (memoized)
      @mock_git.expect :execute, "/path/to/repo", ["rev-parse", "--show-toplevel"]

      result = @resolver.validate_paths(["/path/to/repo/file1.txt", "/path/to/repo/file2.txt"])

      assert_equal ["/path/to/repo/file1.txt", "/path/to/repo/file2.txt"], result[:valid]
      assert_empty result[:invalid]
      @mock_git.verify
    end
  end
end
