# frozen_string_literal: true

require_relative "../test_helper"

class CLITest < GitSecretsTestCase
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

  def test_cli_returns_exit_code
    # Verify that CLI.start returns exit codes for testability
    # (per docs/testing-patterns.md return-code contract)
    @mock_repo.add_file("clean.txt", "no secrets here")

    with_mocked_gitleaks(clean: true) do
      result = nil
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan"])
      end

      assert_equal 0, result
    end
  end

  def test_scan_returns_exit_code_0_when_clean
    @mock_repo.add_file("clean.txt", "no secrets here")

    with_mocked_gitleaks(clean: true) do
      result = nil
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan"])
      end

      assert_equal 0, result
    end
  end

  def test_scan_returns_exit_code_1_when_tokens_found
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
      result = nil
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan"])
      end

      assert_equal 1, result
    end
  end

  def test_version_command
    result = nil
    output, = capture_io do
      result = Ace::Git::Secrets::CLI.start(["version"])
    end

    assert_match(/ace-git-secrets version/, output)
    assert_equal 0, result
  end

  def test_scan_with_format_json
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      result = nil
      output, = capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan", "--report-format", "json"])
      end

      # New behavior: summary to stdout, full JSON report saved to file
      # Verify output mentions report saved and find the file
      assert_match(/Report saved:.*\.json/, output, "Should mention JSON report file")
      assert_equal 0, result

      # Verify the JSON file was created
      cache_dir = File.join(@mock_repo.path, ".cache", "ace-git-secrets")
      json_files = Dir.glob(File.join(cache_dir, "*-report.json"))
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
      result = nil
      output, = capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan", "--verbose"])
      end

      # Verbose mode should show full report
      assert_match(/No tokens detected/, output, "Verbose output should show full message")
      assert_equal 0, result
    end
  end

  def test_scan_with_confidence_filter
    @mock_repo.add_file("clean.yml", "nothing=here")

    with_mocked_gitleaks(clean: true) do
      result = nil
      # High confidence should pass for clean repo
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan", "--confidence", "high"])
      end

      assert_equal 0, result
    end
  end

  def test_check_release_returns_0_when_clean
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      result = nil
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["check-release"])
      end

      assert_equal 0, result
    end
  end

  def test_check_release_returns_1_when_tokens_found
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
      result = nil
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["check-release"])
      end

      assert_equal 1, result
    end
  end

  def test_verbose_option_exists
    # Test that --verbose is a valid option (documented in CLI)
    @mock_repo.add_file("clean.txt", "no secrets")

    with_mocked_gitleaks(clean: true) do
      result = nil
      # Should not raise an error
      capture_io do
        result = Ace::Git::Secrets::CLI.start(["scan", "--verbose"])
      end

      assert_equal 0, result
    end
  end
end
