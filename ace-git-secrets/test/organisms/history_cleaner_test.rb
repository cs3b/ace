# frozen_string_literal: true

require_relative "../test_helper"

class HistoryCleanerTest < GitSecretsTestCase
  def setup
    # Use mock repo for fast tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
    @cleaner = Ace::Git::Secrets::Organisms::HistoryCleaner.new(repository_path: @mock_repo.path)
  end

  def teardown
    @mock_repo&.cleanup
  end

  def test_clean_requires_git_filter_repo
    tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

    @cleaner.rewriter.stub :available?, false do
      result = @cleaner.clean(tokens: tokens)

      refute result[:success]
      assert_match(/git-filter-repo is required/, result[:message])
    end
  end

  def test_clean_requires_clean_working_directory
    # Add file to mock repo (no git subprocess)
    @mock_repo.add_file("file.txt", "content")
    # Add uncommitted file
    @mock_repo.add_file("dirty.txt", "uncommitted")
    tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

    @cleaner.rewriter.stub :available?, true do
      # Stub to simulate dirty working directory
      @cleaner.rewriter.stub :clean_working_directory?, false do
        result = @cleaner.clean(tokens: tokens)

        refute result[:success]
        assert_match(/uncommitted changes/, result[:message])
      end
    end
  end

  def test_clean_returns_success_when_no_tokens_provided
    @mock_repo.add_file("clean.txt", "no secrets here")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        result = @cleaner.clean(tokens: [])

        assert result[:success]
        assert_match(/No tokens found/, result[:message])
        assert_equal 0, result[:tokens_removed]
      end
    end
  end

  def test_clean_requires_confirmation_when_not_forced
    @mock_repo.add_file("secret.txt", "content")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        result = @cleaner.clean(tokens: tokens)

        refute result[:success]
        assert result[:requires_confirmation]
        assert_match(/WARNING.*rewrite Git history/i, result[:message])
        assert_equal "REWRITE HISTORY", result[:confirmation_text]
      end
    end
  end

  def test_dry_run_shows_what_would_be_removed
    @mock_repo.add_file("secret.txt", "content")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        result = @cleaner.clean(tokens: tokens, dry_run: true)

        assert result[:success]
        assert result[:dry_run]
        assert_match(/Would remove 1 token/, result[:message])
        assert_equal 1, result[:tokens].size
      end
    end
  end

  def test_dry_run_works_without_git_filter_repo
    tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

    @cleaner.rewriter.stub :available?, false do
      result = @cleaner.clean(tokens: tokens, dry_run: true)

      assert result[:success]
      assert result[:dry_run]
      assert_match(/Would remove 1 token/, result[:message])
    end
  end

  def test_valid_confirmation_accepts_exact_text
    assert @cleaner.valid_confirmation?("REWRITE HISTORY")
    assert @cleaner.valid_confirmation?("  REWRITE HISTORY  ")
  end

  def test_valid_confirmation_rejects_wrong_text
    refute @cleaner.valid_confirmation?("yes")
    refute @cleaner.valid_confirmation?("REWRITE")
    refute @cleaner.valid_confirmation?("rewrite history")
    refute @cleaner.valid_confirmation?("")
  end

  def test_clean_with_force_skips_confirmation
    @mock_repo.add_file("clean.txt", "no secrets")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        result = @cleaner.clean(tokens: [], force: true)

        assert result[:success]
        refute result[:requires_confirmation]
      end
    end
  end

  def test_clean_creates_backup_by_default
    @mock_repo.add_file("clean.txt", "no secrets")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        # Mock the rewriter to track backup creation
        backup_created = false

        @cleaner.rewriter.stub :create_backup, ->(_path) {
          backup_created = true
          true
        } do
          @cleaner.rewriter.stub :rewrite, ->(_tokens, **_opts) {
            {success: true, message: "Mocked", changes: []}
          } do
            _result = @cleaner.clean(tokens: tokens, force: true, create_backup: true)
            assert backup_created, "Backup should have been created"
          end
        end
      end
    end
  end

  def test_clean_can_skip_backup
    @mock_repo.add_file("clean.txt", "no secrets")

    @cleaner.rewriter.stub :available?, true do
      @cleaner.rewriter.stub :clean_working_directory?, true do
        tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

        backup_created = false

        @cleaner.rewriter.stub :create_backup, ->(_path) {
          backup_created = true
          true
        } do
          @cleaner.rewriter.stub :rewrite, ->(_tokens, **_opts) {
            {success: true, message: "Mocked", changes: []}
          } do
            _result = @cleaner.clean(tokens: tokens, force: true, create_backup: false)
            refute backup_created, "Backup should not have been created"
          end
        end
      end
    end
  end
end
