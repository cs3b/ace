# frozen_string_literal: true

require_relative "../../test_helper"

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

  # ============================================================================
  # Unit tests for clean_working_directory? (stubbed - no real git)
  # Tests the parsing logic by mocking Open3.capture2 responses
  # ============================================================================

  def test_clean_working_directory_returns_true_when_clean
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    Open3.stub :capture2, ["", mock_status] do
      assert @rewriter.clean_working_directory?, "Empty git status output should indicate clean"
    end
  end

  def test_clean_working_directory_returns_false_with_uncommitted_changes
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    # Git status output for modified file
    Open3.stub :capture2, [" M file.txt\n", mock_status] do
      refute @rewriter.clean_working_directory?, "Modified file in status should indicate dirty"
    end
  end

  def test_clean_working_directory_returns_false_with_untracked_files
    mock_status = Minitest::Mock.new
    mock_status.expect :success?, true

    # Git status output for untracked file
    Open3.stub :capture2, ["?? untracked.txt\n", mock_status] do
      refute @rewriter.clean_working_directory?, "Untracked file in status should indicate dirty"
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
