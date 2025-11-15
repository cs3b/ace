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
      result = @resolver.validate_paths(["valid_path", "invalid_path"])

      assert_equal ["valid_path"], result[:valid]
      assert_equal ["invalid_path"], result[:invalid]
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
      refute @resolver.all_paths_exist?(["path1", "path2"])
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

        resolved = @resolver.resolve_paths(paths)

        assert_equal ["lib/file1.rb", "test/file2.rb"], resolved
        @mock_git.verify
      end
    end
  end

  def test_resolve_paths_filters_glob_to_tracked_files_only
    paths = ["lib/*.rb"]

    # Dir.glob returns files including untracked
    Dir.stub :glob, ["lib/tracked.rb", "lib/untracked.rb"] do
      File.stub :file?, ->(path) { true } do
        # Git only knows about tracked.rb
        @mock_git.expect :execute, "lib/tracked.rb\n", ["ls-files"]

        resolved = @resolver.resolve_paths(paths)

        # Should only include tracked file
        assert_equal ["lib/tracked.rb"], resolved
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
          pattern == "lib/*.rb" ? ["lib/file1.rb"] : []
        end do
          File.stub :file?, ->(path) { true } do
            @mock_git.expect :execute, "lib/file1.rb\n", ["ls-files"]
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

  # Tests for within_repository?
  def test_within_repository_returns_true_for_paths_in_repo
    File.stub :exist?, ->(path) { true } do
      File.stub :expand_path, ->(path) {
        # Handle both the file path and repo root
        path == "/repo" ? "/repo" : "/repo/#{path}"
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
end
