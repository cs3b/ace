# frozen_string_literal: true

require_relative "../test_helper"

class HistoryCleanerTest < GitSecretsTestCase
  def setup
    @temp_repo = create_temp_repo
    @cleaner = Ace::Git::Secrets::Organisms::HistoryCleaner.new(repository_path: @temp_repo)
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.exist?(@original_dir)
    cleanup_temp_repo(@temp_repo)
  end

  def test_clean_requires_git_filter_repo
    @cleaner.rewriter.stub :available?, false do
      result = @cleaner.clean(tokens: []) # Pass empty tokens to skip scan

      refute result[:success]
      assert_match(/git-filter-repo is required/, result[:message])
    end
  end

  def test_clean_requires_clean_working_directory
    create_commit(@temp_repo, "file.txt", "content", "Initial")
    Dir.chdir(@temp_repo) { File.write("dirty.txt", "uncommitted") }

    @cleaner.rewriter.stub :available?, true do
      result = @cleaner.clean(tokens: []) # Pass empty tokens to skip scan

      refute result[:success]
      assert_match(/uncommitted changes/, result[:message])
    end
  end

  def test_clean_returns_success_when_no_tokens_provided
    create_commit(@temp_repo, "clean.txt", "no secrets here", "Clean commit")

    @cleaner.rewriter.stub :available?, true do
      result = @cleaner.clean(tokens: [])

      assert result[:success]
      assert_match(/No tokens found/, result[:message])
      assert_equal 0, result[:tokens_removed]
    end
  end

  def test_clean_requires_confirmation_when_not_forced
    create_commit(@temp_repo, "secret.txt", "content", "Add file")

    @cleaner.rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      result = @cleaner.clean(tokens: tokens)

      refute result[:success]
      assert result[:requires_confirmation]
      assert_match(/WARNING.*rewrite Git history/i, result[:message])
      assert_equal "REWRITE HISTORY", result[:confirmation_text]
    end
  end

  def test_dry_run_shows_what_would_be_removed
    create_commit(@temp_repo, "secret.txt", "content", "Add file")

    @cleaner.rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      result = @cleaner.clean(tokens: tokens, dry_run: true)

      assert result[:success]
      assert result[:dry_run]
      assert_match(/Would remove 1 token/, result[:message])
      assert_equal 1, result[:tokens].size
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
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    @cleaner.rewriter.stub :available?, true do
      result = @cleaner.clean(tokens: [], force: true)

      assert result[:success]
      refute result[:requires_confirmation]
    end
  end

  def test_clean_creates_backup_by_default
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    @cleaner.rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      # Mock the rewriter to track backup creation
      backup_created = false

      @cleaner.rewriter.stub :create_backup, ->(path) {
        backup_created = true
        true
      } do
        @cleaner.rewriter.stub :rewrite, ->(_) {
          { success: true, message: "Mocked", changes: [] }
        } do
          result = @cleaner.clean(tokens: tokens, force: true, create_backup: true)
          assert backup_created, "Backup should have been created"
        end
      end
    end
  end

  def test_clean_can_skip_backup
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    @cleaner.rewriter.stub :available?, true do
      tokens = [create_mock_token("ghp_test123456789012345678901234567890AB")]

      backup_created = false

      @cleaner.rewriter.stub :create_backup, ->(_path) {
        backup_created = true
        true
      } do
        @cleaner.rewriter.stub :rewrite, ->(_) {
          { success: true, message: "Mocked", changes: [] }
        } do
          result = @cleaner.clean(tokens: tokens, force: true, create_backup: false)
          refute backup_created, "Backup should not have been created"
        end
      end
    end
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
