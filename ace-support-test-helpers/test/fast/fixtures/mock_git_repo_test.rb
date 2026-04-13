# frozen_string_literal: true

require_relative "../../test_helper"

# Tests for MockGitRepo fixture
# Verifies edge cases and the block initializer pattern
class MockGitRepoTest < AceTestCase
  def setup
    @repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new
  end

  def teardown
    @repo&.cleanup
  end

  # ============================================================================
  # Block Initializer Tests
  # ============================================================================

  def test_block_initializer_yields_self
    yielded_repo = nil

    repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new do |r|
      yielded_repo = r
    end

    assert_same repo, yielded_repo, "Block should receive the repo instance"
  ensure
    repo&.cleanup
  end

  def test_block_initializer_allows_inline_setup
    repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new do |r|
      r.add_file("config.yml", "key: value")
      r.add_commit("abc1234", message: "Add config")
    end

    assert File.exist?(File.join(repo.path, "config.yml")), "File should be created"
    assert_equal 1, repo.commits.size, "Commit should be recorded"
  ensure
    repo&.cleanup
  end

  def test_works_without_block
    repo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo.new

    assert Dir.exist?(repo.path), "Path should exist without block"
    assert Dir.exist?(File.join(repo.path, ".git")), ".git directory should exist"
  ensure
    repo&.cleanup
  end

  # ============================================================================
  # Nested Directory Tests
  # ============================================================================

  def test_add_file_creates_nested_directories
    @repo.add_file("deeply/nested/path/to/file.txt", "content")

    full_path = File.join(@repo.path, "deeply/nested/path/to/file.txt")
    assert File.exist?(full_path), "Nested file should be created"
    assert_equal "content", File.read(full_path), "Content should be correct"
  end

  def test_add_file_handles_multiple_nested_paths
    @repo.add_file("src/components/Button.tsx", "export const Button = () => {}")
    @repo.add_file("src/components/Input.tsx", "export const Input = () => {}")
    @repo.add_file("test/components/Button.test.tsx", "describe('Button', () => {})")

    assert File.exist?(File.join(@repo.path, "src/components/Button.tsx"))
    assert File.exist?(File.join(@repo.path, "src/components/Input.tsx"))
    assert File.exist?(File.join(@repo.path, "test/components/Button.test.tsx"))
  end

  def test_add_file_tracks_nested_files_correctly
    @repo.add_file("a/b/c.txt", "content1")
    @repo.add_file("x/y/z.txt", "content2")

    assert_equal 2, @repo.files.size
    assert @repo.files.key?("a/b/c.txt")
    assert @repo.files.key?("x/y/z.txt")
  end

  # ============================================================================
  # Large File / Content Tests
  # ============================================================================

  def test_add_file_handles_large_content
    large_content = "x" * 100_000 # 100KB of content

    @repo.add_file("large.txt", large_content)

    full_path = File.join(@repo.path, "large.txt")
    assert File.exist?(full_path)
    assert_equal 100_000, File.read(full_path).length
  end

  def test_add_file_handles_binary_like_content
    binary_content = (0..255).map(&:chr).join # All byte values

    @repo.add_file("binary.bin", binary_content)

    full_path = File.join(@repo.path, "binary.bin")
    assert File.exist?(full_path)
    assert_equal binary_content.bytes, File.read(full_path).bytes
  end

  def test_add_file_handles_multiline_content
    multiline = <<~CONTENT
      line 1
      line 2
      line 3
    CONTENT

    @repo.add_file("multiline.txt", multiline)

    assert_equal multiline, File.read(File.join(@repo.path, "multiline.txt"))
  end

  # ============================================================================
  # Reset Tests
  # ============================================================================

  def test_reset_clears_files_and_commits
    @repo.add_file("file1.txt", "content1")
    @repo.add_file("file2.txt", "content2")
    @repo.add_commit("abc1234", message: "Add files")

    @repo.reset!

    assert_empty @repo.files, "Files should be cleared"
    assert_empty @repo.commits, "Commits should be cleared"
  end

  def test_reset_preserves_git_directory
    @repo.add_file("file.txt", "content")
    @repo.reset!

    assert Dir.exist?(File.join(@repo.path, ".git")), ".git directory should remain"
  end

  def test_reset_removes_actual_files
    @repo.add_file("file.txt", "content")
    file_path = File.join(@repo.path, "file.txt")

    assert File.exist?(file_path), "File should exist before reset"

    @repo.reset!

    refute File.exist?(file_path), "File should be removed after reset"
  end

  def test_reset_removes_nested_directories
    @repo.add_file("deep/nested/file.txt", "content")

    @repo.reset!

    refute Dir.exist?(File.join(@repo.path, "deep")), "Nested directories should be removed"
  end

  # ============================================================================
  # Commit Tracking Tests
  # ============================================================================

  def test_add_commit_records_files_at_commit_time
    @repo.add_file("file1.txt", "content1")
    @repo.add_commit("abc1234", message: "First")

    @repo.add_file("file2.txt", "content2")
    @repo.add_commit("def5678", message: "Second")

    # First commit should only have file1
    assert_equal ["file1.txt"], @repo.commits.first[:files]

    # Second commit should have both files
    assert_includes @repo.commits.last[:files], "file1.txt"
    assert_includes @repo.commits.last[:files], "file2.txt"
  end

  def test_head_returns_latest_commit_hash
    @repo.add_commit("abc1234", message: "First")
    @repo.add_commit("def5678", message: "Second")

    assert_equal "def5678", @repo.head
  end

  def test_head_returns_nil_with_no_commits
    assert_nil @repo.head
  end

  # ============================================================================
  # Path Edge Cases
  # ============================================================================

  def test_add_file_handles_dotfiles
    @repo.add_file(".gitignore", "*.log\nnode_modules/")
    @repo.add_file(".env", "SECRET=abc")

    assert File.exist?(File.join(@repo.path, ".gitignore"))
    assert File.exist?(File.join(@repo.path, ".env"))
  end

  def test_add_file_handles_special_characters_in_names
    @repo.add_file("file with spaces.txt", "content")
    @repo.add_file("file-with-dashes.txt", "content")
    @repo.add_file("file_with_underscores.txt", "content")

    assert File.exist?(File.join(@repo.path, "file with spaces.txt"))
    assert File.exist?(File.join(@repo.path, "file-with-dashes.txt"))
    assert File.exist?(File.join(@repo.path, "file_with_underscores.txt"))
  end

  # ============================================================================
  # Cleanup Tests
  # ============================================================================

  def test_cleanup_removes_directory
    path = @repo.path
    assert Dir.exist?(path), "Path should exist before cleanup"

    @repo.cleanup

    refute Dir.exist?(path), "Path should not exist after cleanup"
    @repo = nil # Prevent double cleanup in teardown
  end

  def test_cleanup_is_idempotent
    path = @repo.path
    @repo.cleanup
    @repo.cleanup # Should not raise

    refute Dir.exist?(path)
    @repo = nil
  end
end
