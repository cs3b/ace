# frozen_string_literal: true

require_relative "../../test_helper"

class CLITest < GitSecretsTestCase
  def dispatch_cli(args)
    Ace::Support::Cli::Runner.new(Ace::Git::Secrets::CLI).call(args: args)
  end

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

  # Note: ace-support-cli returns command metadata, not process exit codes.
  # Exit code behavior is verified at integration level via executable tests.

  def test_cli_completes_scan_successfully_when_clean
    # Verify that CLI.start runs scan without error on clean repo
    @mock_repo.add_file("clean.txt", "no secrets here")

    with_mocked_gitleaks(clean: true) do
      output, = capture_io do
        dispatch_cli(["scan"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # Clean scan should show success message
      assert_match(/No tokens detected|clean/i, output)
    end
  end

  def test_scan_reports_tokens_when_found
    @mock_repo.add_file("secret.txt", "API_KEY=ghp_SecretToken1234567890ABCDEFGHIJ")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_SecretToken1234567890ABCDEFGHIJ",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      output, = capture_io do
        dispatch_cli(["scan"])
      rescue SystemExit
        # ace-support-cli may call exit
      rescue Ace::Support::Cli::Error
        # CLI raises Error with exit_code when tokens found
      end

      # Should report findings
      assert_match(/found|detected|token/i, output)
    end
  end

  def test_version_command
    output, = capture_io do
      dispatch_cli(["version"])
    rescue SystemExit
      # ace-support-cli may call exit for some commands
    end

    assert_match(/ace-git-secrets/, output)
  end

  def test_version_long_flag
    output, = capture_io do
      dispatch_cli(["--version"])
    rescue SystemExit
      # ace-support-cli may call exit for some commands
    end

    assert_match(/ace-git-secrets/, output)
  end

  def test_scan_with_format_json
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      output, = capture_io do
        dispatch_cli(["scan", "--report-format", "json"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # New behavior: summary to stdout, full JSON report saved to file
      # Verify output mentions report saved and find the file
      assert_match(/Report saved:.*\.json/, output, "Should mention JSON report file")

      # Verify the JSON file was created in sessions/ subdirectory
      sessions_dir = File.join(@mock_repo.path, ".ace-local", "git-secrets", "sessions")
      json_files = Dir.glob(File.join(sessions_dir, "*-report.json"))
      assert json_files.any?, "JSON report file should exist"

      # Verify the JSON content
      content = File.read(json_files.first)
      parsed = JSON.parse(content)
      assert parsed.key?("scan_metadata"), "JSON should have scan_metadata"
    end
  end

  def test_scan_verbose_shows_full_report
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      output, = capture_io do
        dispatch_cli(["scan", "--verbose"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # Verbose mode should show full report
      assert_match(/No tokens detected/, output, "Verbose output should show full message")
    end
  end

  def test_scan_with_confidence_filter
    @mock_repo.add_file("clean.yml", "nothing=here")

    with_mocked_gitleaks(clean: true) do
      # High confidence should pass for clean repo - verify no error
      _, stderr = capture_io do
        dispatch_cli(["scan", "--confidence", "high"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # Should not show error
      refute_match(/error/i, stderr)
    end
  end

  def test_check_release_succeeds_when_clean
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      output, = capture_io do
        dispatch_cli(["check-release"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # Should show release gate message
      assert_match(/pre-release|check/i, output)
    end
  end

  def test_check_release_reports_tokens_when_found
    @mock_repo.add_file("secret.txt", "API_KEY=ghp_SecretToken1234567890ABCDEFGHIJ")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_SecretToken1234567890ABCDEFGHIJ",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      output, = capture_io do
        dispatch_cli(["check-release"])
      rescue SystemExit
        # ace-support-cli may call exit
      rescue Ace::Support::Cli::Error
        # CLI raises Error with exit_code when tokens found
      end

      # Should report tokens found
      assert_match(/found|detected|fail/i, output)
    end
  end

  def test_verbose_option_exists
    # Test that --verbose is a valid option (documented in CLI)
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      # Should not raise an error
      _, stderr = capture_io do
        dispatch_cli(["scan", "--verbose"])
      rescue SystemExit
        # ace-support-cli may call exit
      end

      # Should not show error about unknown option
      refute_match(/unknown option|invalid/i, stderr)
    end
  end

  def test_help_command
    output, stderr = capture_io do
      dispatch_cli(["help"])
    rescue SystemExit
      # ace-support-cli calls exit(0) for help
    end

    # ace-support-cli help goes to stderr
    combined = output + stderr
    assert_match(/COMMANDS|Commands:/, combined)
  end

  def test_help_for_scan_command
    output, stderr = capture_io do
      dispatch_cli(["help", "scan"])
    rescue SystemExit
      # ace-support-cli calls exit(0) for help
    end

    # ace-support-cli help goes to stderr
    combined = output + stderr
    assert_match(/scan/, combined)
  end
end
