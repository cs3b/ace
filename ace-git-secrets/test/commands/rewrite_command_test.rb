# frozen_string_literal: true

require_relative "../test_helper"

class RewriteCommandTest < GitSecretsTestCase
  def setup
    skip "gitleaks not installed" unless gitleaks_available?
    @temp_repo = create_temp_repo
    @original_dir = Dir.pwd
    Dir.chdir(@temp_repo)
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    cleanup_temp_repo(@temp_repo) if @temp_repo
  end

  def test_dry_run_returns_success_with_no_changes
    # Use high-entropy token that gitleaks will detect
    create_commit(@temp_repo, "secret.txt", "TOKEN=literal:[REDACTED:github-pat]", "Add secret")

    with_rewriter_availability(true) do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          dry_run: true
        )
        assert_equal 0, exit_code
      end

      assert_match(/DRY RUN/i, output)
    end
  end

  def test_requires_confirmation_without_force
    # Use high-entropy token that gitleaks will detect
    create_commit(@temp_repo, "secret.txt", "TOKEN=literal:[REDACTED:github-pat]", "Add secret")

    # Simulate user not providing confirmation (empty stdin)
    mock_stdin = StringIO.new("\n")

    output = nil
    exit_code = nil

    original_stdin = $stdin
    begin
      $stdin = mock_stdin

      with_rewriter_availability(true) do
        output, = capture_io do
          exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
            force: false,
            backup: false
          )
        end
      end
    ensure
      $stdin = original_stdin
    end

    # Should fail without proper confirmation
    assert_equal 1, exit_code
    assert_match(/Confirmation failed/i, output)
  end

  def test_returns_error_when_git_filter_repo_unavailable
    # Use high-entropy token that gitleaks will detect
    create_commit(@temp_repo, "secret.txt", "TOKEN=literal:[REDACTED:github-pat]", "Add secret")

    with_rewriter_availability(false) do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          force: true
        )
        assert_equal 1, exit_code
      end

      assert_match(/git-filter-repo is required/i, output)
    end
  end

  def test_returns_success_when_no_tokens_found
    create_commit(@temp_repo, "clean.txt", "no secrets here", "Clean commit")

    with_rewriter_availability(true) do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          force: true
        )
        assert_equal 0, exit_code
      end

      assert_match(/No tokens found/i, output)
    end
  end

  private

  def gitleaks_available?
    Ace::Git::Secrets::Atoms::GitleaksRunner.available?
  end
end
