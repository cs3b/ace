# frozen_string_literal: true

require_relative "../test_helper"

class CLITest < GitSecretsTestCase
  def setup
    skip "gitleaks not installed" unless gitleaks_available?
    @temp_repo = create_temp_repo
    @original_dir = Dir.pwd
    Dir.chdir(@temp_repo)
    # Reset exit code before each test
    Ace::Git::Secrets::CLI.last_exit_code = nil
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    cleanup_temp_repo(@temp_repo) if @temp_repo
  end

  def test_cli_does_not_call_exit
    # Verify that CLI methods set last_exit_code instead of calling exit
    # This is critical for testability (per docs/testing-patterns.md)
    create_commit(@temp_repo, "clean.txt", "no secrets here", "Clean commit")

    # If CLI called exit(), this would terminate the test process
    capture_io do
      Ace::Git::Secrets::CLI.start(["scan"])
    end

    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_scan_returns_exit_code_0_when_clean
    create_commit(@temp_repo, "clean.txt", "no secrets here", "Clean commit")

    capture_io do
      Ace::Git::Secrets::CLI.start(["scan"])
    end

    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_scan_returns_exit_code_1_when_tokens_found
    # Use high-entropy token that gitleaks will detect
    create_commit(@temp_repo, "secret.txt", "API_KEY=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    capture_io do
      Ace::Git::Secrets::CLI.start(["scan"])
    end

    assert_equal 1, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_version_command
    output, = capture_io do
      Ace::Git::Secrets::CLI.start(["version"])
    end

    assert_match(/ace-git-secrets version/, output)
    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_scan_with_format_json
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    output, = capture_io do
      Ace::Git::Secrets::CLI.start(["scan", "--report-format", "json"])
    end

    # New behavior: summary to stdout, full JSON report saved to file
    # Verify output mentions report saved and find the file
    assert_match(/Report saved:.*\.json/, output, "Should mention JSON report file")
    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code

    # Verify the JSON file was created
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    json_files = Dir.glob(File.join(cache_dir, "*-report.json"))
    assert json_files.any?, "JSON report file should exist"

    # Verify the JSON content
    content = File.read(json_files.first)
    parsed = JSON.parse(content)
    assert parsed.key?("scan_metadata"), "JSON should have scan_metadata"
  end

  def test_scan_verbose_shows_full_report
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    output, = capture_io do
      Ace::Git::Secrets::CLI.start(["scan", "--verbose"])
    end

    # Verbose mode should show full report
    assert_match(/No tokens detected/, output, "Verbose output should show full message")
    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_scan_with_confidence_filter
    create_commit(@temp_repo, "clean.yml", "nothing=here", "No tokens")

    # High confidence should pass for clean repo
    capture_io do
      Ace::Git::Secrets::CLI.start(["scan", "--confidence", "high"])
    end

    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_check_release_returns_0_when_clean
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    capture_io do
      Ace::Git::Secrets::CLI.start(["check-release"])
    end

    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_check_release_returns_1_when_tokens_found
    # Use high-entropy token that gitleaks will detect
    create_commit(@temp_repo, "secret.txt", "API_KEY=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    capture_io do
      Ace::Git::Secrets::CLI.start(["check-release"])
    end

    assert_equal 1, Ace::Git::Secrets::CLI.last_exit_code
  end

  def test_verbose_option_exists
    # Test that --verbose is a valid option (documented in CLI)
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    # Should not raise an error
    capture_io do
      Ace::Git::Secrets::CLI.start(["scan", "--verbose"])
    end

    assert_equal 0, Ace::Git::Secrets::CLI.last_exit_code
  end

  private

  def gitleaks_available?
    Ace::Git::Secrets::Atoms::GitleaksRunner.available?
  end
end
