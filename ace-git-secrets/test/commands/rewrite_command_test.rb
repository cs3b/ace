# frozen_string_literal: true

require "json"
require_relative "../test_helper"

class RewriteCommandTest < GitSecretsTestCase
  def setup
    # Use mock repo for fast tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
    @original_dir = Dir.pwd
    Dir.chdir(@mock_repo.path)
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    @mock_repo&.cleanup
  end

  def test_dry_run_returns_success_with_no_changes
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_TestTokenForDryRun1234567890ABCDEF")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_TestTokenForDryRun1234567890ABCDEF",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_rewrite_test_mocks(findings: mock_findings) do
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
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_TestTokenForConfirm1234567890ABCDEF")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_TestTokenForConfirm1234567890ABCDEF",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    # Simulate user not providing confirmation (empty stdin)
    mock_stdin = StringIO.new("\n")

    output = nil
    exit_code = nil

    original_stdin = $stdin
    begin
      $stdin = mock_stdin

      with_rewrite_test_mocks(findings: mock_findings) do
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
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_TestTokenUnavailable1234567890ABCDEF")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_TestTokenUnavailable1234567890ABCDEF",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_rewrite_test_mocks(findings: mock_findings, rewriter_available: false) do
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
    @mock_repo.add_file("clean.txt", "no secrets here")

    with_rewrite_test_mocks do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          force: true
        )
        assert_equal 0, exit_code
      end

      assert_match(/No tokens found/i, output)
    end
  end

  def test_returns_failure_when_scan_file_lacks_raw_value
    broken_report_path = File.join(@mock_repo.path, "broken-report.json")
    File.write(
      broken_report_path,
      JSON.generate(
        {
          "tokens" => [
            {
              "token_type" => "github_pat_classic",
              "pattern_name" => "github_pat_classic",
              "confidence" => "high",
              "commit_hash" => "abc1234",
              "file_path" => "secret.txt",
              "line_number" => 1
            }
          ]
        }
      )
    )

    with_rewrite_test_mocks do
      _stdout, stderr = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          force: true,
          scan_file: broken_report_path
        )
        assert_equal 1, exit_code
      end

      assert_match(/missing raw_value/i, stderr)
    end
  end
end
