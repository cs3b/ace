# frozen_string_literal: true

require_relative "../test_helper"

class GitRewriterTest < GitSecretsTestCase
  def setup
    @temp_repo = create_temp_repo
    @rewriter = Ace::Git::Secrets::Molecules::GitRewriter.new(repository_path: @temp_repo)
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.exist?(@original_dir)
    cleanup_temp_repo(@temp_repo)
  end

  def test_available_returns_true_when_git_filter_repo_installed
    # This test checks if git-filter-repo is in PATH
    # Skip if not installed (common in CI)
    skip "git-filter-repo not installed" unless system("which git-filter-repo > /dev/null 2>&1")
    assert @rewriter.available?
  end

  def test_available_returns_false_when_git_filter_repo_not_installed
    # Stub the system call to simulate missing tool
    @rewriter.stub :available?, false do
      refute @rewriter.available?
    end
  end

  def test_clean_working_directory_returns_true_when_clean
    create_commit(@temp_repo, "file.txt", "content", "Initial")
    assert @rewriter.clean_working_directory?
  end

  def test_clean_working_directory_returns_false_with_uncommitted_changes
    create_commit(@temp_repo, "file.txt", "content", "Initial")

    Dir.chdir(@temp_repo) do
      File.write("new_file.txt", "uncommitted")
    end

    refute @rewriter.clean_working_directory?
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
    create_commit(@temp_repo, "file.txt", "content", "Initial")
    Dir.chdir(@temp_repo) { File.write("dirty.txt", "uncommitted") }

    @rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      result = @rewriter.rewrite(tokens)

      refute result[:success]
      assert_match(/uncommitted changes/, result[:message])
    end
  end

  def test_rewrite_returns_success_with_empty_tokens
    create_commit(@temp_repo, "file.txt", "content", "Initial")

    @rewriter.stub :available?, true do
      result = @rewriter.rewrite([])

      assert result[:success]
      assert_equal "No tokens to remove", result[:message]
    end
  end

  def test_dry_run_shows_what_would_be_removed
    create_commit(@temp_repo, "file.txt", "content", "Initial")

    @rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      result = @rewriter.rewrite(tokens, dry_run: true)

      assert result[:success]
      assert result[:dry_run]
      assert_match(/Would remove 1 token/, result[:message])
      assert_equal 1, result[:changes].size
      assert_equal "ghp_test123456789012345678901234567890AB", result[:changes].first[:original]
    end
  end

  def test_create_backup_creates_mirror_clone
    create_commit(@temp_repo, "file.txt", "content", "Initial")

    backup_path = File.join(File.dirname(@temp_repo), "backup-#{Time.now.to_i}.git")

    begin
      result = @rewriter.create_backup(backup_path)

      assert result
      assert Dir.exist?(backup_path)
    ensure
      FileUtils.rm_rf(backup_path) if Dir.exist?(backup_path)
    end
  end

  def test_create_backup_returns_false_on_failure
    # Try to backup to an invalid path
    result = @rewriter.create_backup("/nonexistent/path/backup.git")
    refute result
  end

  private

  def create_mock_token(raw_value)
    Ace::Git::Secrets::Models::DetectedToken.new(
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc1234",
      file_path: "secret.txt",
      raw_value: raw_value,
      detected_by: "test"
    )
  end
end
