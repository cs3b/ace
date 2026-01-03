# frozen_string_literal: true

require_relative "../test_helper"

class GitRewriterTest < GitSecretsTestCase
  def setup
    # Use mock repo for unit tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
    @rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: @mock_repo.path)
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.exist?(@original_dir)
    @mock_repo&.cleanup
  end

  def test_available_returns_true_when_git_filter_repo_installed
    # This test checks if git-filter-repo is in PATH
    # Skip if not installed (common in CI)
    skip "git-filter-repo not installed" unless system("which git-filter-repo > /dev/null 2>&1")
    assert @rewriter.available?
  end

  # ============================================================================
  # Real-git tests for clean_working_directory? detection
  # These use create_temp_repo for actual git status verification
  # ============================================================================

  def test_clean_working_directory_returns_true_when_clean
    # Use real git repo to test actual status detection
    temp_repo = create_temp_repo
    begin
      create_commit(temp_repo, "file.txt", "content", "Initial")
      rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: temp_repo)

      assert rewriter.clean_working_directory?, "Repository with no uncommitted changes should be clean"
    ensure
      cleanup_temp_repo(temp_repo)
    end
  end

  def test_clean_working_directory_returns_false_with_uncommitted_changes
    # Use real git repo to test dirty state detection
    temp_repo = create_temp_repo
    begin
      create_commit(temp_repo, "file.txt", "content", "Initial")
      # Create uncommitted change
      File.write(File.join(temp_repo, "file.txt"), "modified content")
      rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: temp_repo)

      refute rewriter.clean_working_directory?, "Repository with modified files should not be clean"
    ensure
      cleanup_temp_repo(temp_repo)
    end
  end

  def test_clean_working_directory_returns_false_with_untracked_files
    # Use real git repo to test untracked file detection
    temp_repo = create_temp_repo
    begin
      create_commit(temp_repo, "file.txt", "content", "Initial")
      # Create untracked file
      File.write(File.join(temp_repo, "untracked.txt"), "new file")
      rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: temp_repo)

      refute rewriter.clean_working_directory?, "Repository with untracked files should not be clean"
    ensure
      cleanup_temp_repo(temp_repo)
    end
  end

  def test_rewrite_returns_error_when_git_filter_repo_unavailable
    @rewriter.stub :available?, false do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      result = @rewriter.rewrite(tokens)

      refute result[:success]
      assert_match(/git-filter-repo is required/, result[:message])
      assert_empty result[:changes]
    end
  end

  def test_rewrite_returns_error_when_working_directory_dirty
    @mock_repo.add_file("file.txt", "content")

    @rewriter.stub :available?, true do
      @rewriter.stub :clean_working_directory?, false do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        result = @rewriter.rewrite(tokens)

        refute result[:success]
        assert_match(/uncommitted changes/, result[:message])
      end
    end
  end

  def test_rewrite_returns_success_with_empty_tokens
    @mock_repo.add_file("file.txt", "content")

    @rewriter.stub :available?, true do
      @rewriter.stub :clean_working_directory?, true do
        result = @rewriter.rewrite([])

        assert result[:success]
        assert_equal "No tokens to remove", result[:message]
      end
    end
  end

  def test_dry_run_shows_what_would_be_removed
    @mock_repo.add_file("file.txt", "content")

    @rewriter.stub :available?, true do
      @rewriter.stub :clean_working_directory?, true do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        result = @rewriter.rewrite(tokens, dry_run: true)

        assert result[:success]
        assert result[:dry_run]
        assert_match(/Would remove 1 token/, result[:message])
        assert_equal 1, result[:changes].size
        assert_equal "ghp_test123456789012345678901234567890AB", result[:changes].first[:original]
      end
    end
  end

  def test_create_backup_creates_mirror_clone
    # This test needs a real git repo to test backup functionality
    # Using create_temp_repo for this specific integration test
    temp_repo = create_temp_repo
    create_commit(temp_repo, "file.txt", "content", "Initial")
    rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: temp_repo)

    backup_path = File.join(File.dirname(temp_repo), "backup-#{Time.now.to_i}.git")

    begin
      result = rewriter.create_backup(backup_path)

      assert result
      assert Dir.exist?(backup_path)
    ensure
      FileUtils.rm_rf(backup_path) if Dir.exist?(backup_path)
      cleanup_temp_repo(temp_repo)
    end
  end

  def test_create_backup_returns_false_on_failure
    # Try to backup to an invalid path
    result = @rewriter.create_backup("/nonexistent/path/backup.git")
    refute result
  end
end
