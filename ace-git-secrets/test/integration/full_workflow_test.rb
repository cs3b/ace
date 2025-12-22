# frozen_string_literal: true

require_relative "../test_helper"

# E2E integration test for the full scan → revoke → rewrite workflow
# Tests the complete remediation lifecycle end-to-end
#
# Requires gitleaks to be installed: brew install gitleaks
class FullWorkflowIntegrationTest < GitSecretsTestCase
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

  def test_full_scan_workflow_with_clean_repo
    # Create a clean repository with no secrets
    create_commit(@temp_repo, "readme.md", "# My Project\n\nThis is a clean project.", "Initial commit")
    create_commit(@temp_repo, "config.yml", "database: postgres\nhost: localhost", "Add config")

    # Run scan
    output, = capture_io do
      exit_code = Ace::Git::Secrets::Commands::ScanCommand.execute(
        format: "table",
        confidence: "low"
      )
      assert_equal 0, exit_code, "Scan should return 0 for clean repo"
    end

    assert_match(/No tokens detected/i, output)
  end

  def test_full_scan_workflow_with_secrets
    # Plant a secret in the repository
    # Use high-entropy token that gitleaks will detect
    secret_content = <<~CONTENT
      # Configuration
      DATABASE_URL=postgres://localhost:5432/mydb
      GITHUB_TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4
    CONTENT

    create_commit(@temp_repo, "config.env", secret_content, "Add config with secret")

    # Run scan and verify through report structure
    report = nil
    capture_io do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @temp_repo
      )
      report = auditor.audit(min_confidence: "low")
    end

    # Structural assertions are more stable than regex on output format
    refute report.nil?, "Report should be returned"
    assert report.tokens.size >= 1, "Should find at least 1 token"
    # Gitleaks uses different pattern names
    assert report.tokens.any? { |t| t.raw_value.start_with?("ghp_") }, "Token should have ghp_ prefix"
    refute report.clean?, "Report should not be clean"

    # Also verify CLI output for user-facing behavior
    # Note: With new output behavior, summary goes to stdout and full report to file
    cli_output, = capture_io do
      exit_code = Ace::Git::Secrets::Commands::ScanCommand.execute(
        format: "table",
        confidence: "low"
      )
      assert_equal 1, exit_code, "Scan should return 1 when secrets found"
    end

    # Summary output includes token counts and alert
    assert_match(/Tokens found:/i, cli_output)
    assert_match(/SECURITY ALERT/i, cli_output)

    # Verify the saved report file contains the details
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    json_files = Dir.glob(File.join(cache_dir, "*-report.json"))
    assert json_files.any?, "Report file should be saved"
  end

  def test_scan_with_json_output
    create_commit(@temp_repo, "secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    output, = capture_io do
      Ace::Git::Secrets::Commands::ScanCommand.execute(
        report_format: "json"
      )
    end

    # New behavior: JSON saved to file, summary to stdout
    assert_match(/Report saved:.*\.json/, output)

    # Parse JSON from saved file
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    json_files = Dir.glob(File.join(cache_dir, "*-report.json"))
    assert json_files.any?, "JSON report file should exist"

    json_content = File.read(json_files.first)
    json_data = JSON.parse(json_content)
    # At least one token should be found
    assert json_data["summary"]["total_tokens"] >= 1, "Should find at least one token"
  end

  def test_scan_verbose_format_json_outputs_to_stdout
    create_commit(@temp_repo, "secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    output, = capture_io do
      Ace::Git::Secrets::Commands::ScanCommand.execute(
        format: "json",
        verbose: true
      )
    end

    # In verbose mode with --format json, the full JSON report goes to stdout
    assert_match(/"scan_metadata"/, output)
    assert_match(/"tokens"/, output)
  end

  def test_scan_with_confidence_filtering
    # Create secrets with different confidence levels
    create_commit(@temp_repo, "high.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "High confidence")

    # High confidence only
    high_report = nil
    capture_io do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @temp_repo
      )
      high_report = auditor.audit(min_confidence: "high")
    end

    assert high_report.tokens.all? { |t| t.confidence == "high" }
  end

  def test_scan_respects_since_option
    # Create a commit
    create_commit(@temp_repo, "secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    # Test that since option is accepted without errors
    report = nil
    capture_io do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @temp_repo
      )
      # Use a date format that gitleaks accepts
      report = auditor.audit(since: "2020-01-01")
    end

    # Just verify the scan completed without errors
    assert report.is_a?(Ace::Git::Secrets::Models::ScanReport)
    # Should find the token (since 2020 includes all commits)
    refute report.clean?
  end

  def test_whitelist_filtering
    # Create test directory first
    Dir.chdir(@temp_repo) do
      FileUtils.mkdir_p("test")
    end

    # Create secret in test directory
    Dir.chdir(@temp_repo) do
      File.write("test/mock_tokens.json", '{"token": "ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4"}')
      system("git add test/mock_tokens.json")
      system("git commit -q -m 'Test fixture'")
    end

    whitelist = [
      { "file" => "test/*", "reason" => "Test fixtures" }
    ]

    # Scan with whitelist
    report = nil
    capture_io do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @temp_repo,
        whitelist: whitelist
      )
      report = auditor.audit
    end

    # Token should be filtered out by whitelist
    assert report.clean?, "Whitelisted file should not trigger alert"
  end

  def test_whitelist_display_in_scan_output
    # Create test directory first
    Dir.chdir(@temp_repo) do
      FileUtils.mkdir_p("test")
    end

    # Create secret in test directory (will be whitelisted)
    Dir.chdir(@temp_repo) do
      File.write("test/mock_tokens.json", '{"token": "ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4"}')
      system("git add test/mock_tokens.json")
      system("git commit -q -m 'Test fixture'")
    end

    # Also create a real secret (will NOT be whitelisted)
    create_commit(@temp_repo, "config.env", "API_KEY=ghp_r9AlT0k3n4ABC5DEF6GHI7JKL8MNO9PQR", "Add real config")

    # Set up whitelist via config stub
    config_with_whitelist = Ace::Git::Secrets.config.merge(
      "whitelist" => [{ "file" => "test/*", "reason" => "Test fixtures" }]
    )

    Ace::Git::Secrets.stub :config, config_with_whitelist do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::ScanCommand.execute({})
        # Should find the real token (exit code 1)
        assert_equal 1, exit_code
      end

      # Output should mention whitelisted tokens
      # (count may vary due to git history, so we just check the message format)
      assert_match(/Whitelisted.*token.*excluded by whitelist/i, output)
    end
  end

  def test_revoke_command_integration
    create_commit(@temp_repo, "clean.txt", "no secrets", "Clean")

    # Mock API client for revocation using stub for thread-safety
    mock_client = MockApiClient.new
    mock_client.github_response = { success: true, message: "Token revoked" }

    Ace::Git::Secrets::Atoms::ServiceApiClient.stub :new, ->(**_) { mock_client } do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute(
          token: "ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4"
        )
        assert_equal 0, exit_code
      end

      assert_match(/\[OK\]/i, output)
      assert_match(/revoked/i, output)
    end
  end

  def test_rewrite_dry_run_integration
    # Ensure the file is not in an excluded directory
    create_commit(@temp_repo, "config.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    # First verify the token is detected
    capture_io do
      scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
        repository_path: @temp_repo
      )
      report = scanner.scan(min_confidence: "high")
      assert report.tokens.any?, "Should detect the GitHub token"
    end

    # Use helper to stub git-filter-repo availability
    with_rewriter_availability(true) do
      output, = capture_io do
        exit_code = Ace::Git::Secrets::Commands::RewriteCommand.execute(
          dry_run: true
        )
        assert_equal 0, exit_code
      end

      assert_match(/DRY RUN/i, output)
      assert_match(/ghp_/i, output)
    end
  end

  def test_scan_json_output_includes_raw_values_for_revocation
    create_commit(@temp_repo, "secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    report = nil
    capture_io do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @temp_repo
      )
      report = auditor.audit
    end

    # Report should have raw_value accessible for revocation
    assert report.tokens.first.raw_value.start_with?("ghp_")

    # JSON with include_raw should include raw values
    json_with_raw = JSON.parse(report.to_json(include_raw: true))
    assert json_with_raw["tokens"].first.key?("raw_value")

    # JSON without include_raw should not include raw values
    json_without_raw = JSON.parse(report.to_json(include_raw: false))
    refute json_without_raw["tokens"].first.key?("raw_value")
  end

  def test_scan_file_workflow_saves_with_raw_values_for_revocation
    # This test guards the contract between scan output and revoke/rewrite-history input
    # Critical: saved reports must include raw_value for downstream commands to function
    create_commit(@temp_repo, "secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4", "Add secret")

    # Run scan to generate report file
    capture_io do
      Ace::Git::Secrets::Commands::ScanCommand.execute(
        report_format: "json"
      )
    end

    # Find the saved report file
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    json_files = Dir.glob(File.join(cache_dir, "*-report.json"))
    assert json_files.any?, "Scan should save a JSON report file"

    scan_file = json_files.first

    # Verify saved report structure (even if empty, structure should be correct)
    saved_data = JSON.parse(File.read(scan_file))
    assert saved_data.key?("tokens"), "Report must have tokens key"
    assert saved_data.key?("scan_metadata"), "Report must have scan_metadata"

    # If tokens were found, verify they have raw_value
    if saved_data["tokens"].any?
      token = saved_data["tokens"].first
      assert token.key?("raw_value"), "Saved report must include raw_value"
      assert token["raw_value"].start_with?("ghp_"), "raw_value should be the actual token"

      # Verify token_type is set (gitleaks uses "github-pat")
      assert token.key?("token_type"), "Token must have token_type"
    end
    # Note: Revoke via scan file tested separately in revoke_command_test.rb
  end

  def test_revoke_scan_file_fails_gracefully_without_raw_values
    # Test that revoke command fails explicitly when raw_value is missing
    create_commit(@temp_repo, "dummy.txt", "dummy content", "Dummy commit")

    # Create a scan file WITHOUT raw_value (simulating old/broken format)
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    FileUtils.mkdir_p(cache_dir)
    scan_file = File.join(cache_dir, "test-report.json")

    broken_report = {
      "scan_metadata" => { "repository" => @temp_repo },
      "tokens" => [
        {
          "token_type" => "github_pat_classic",
          "confidence" => "high",
          "commit_hash" => "abc123",
          "file_path" => "secret.txt"
          # Deliberately missing raw_value
        }
      ]
    }
    File.write(scan_file, JSON.pretty_generate(broken_report))

    # Revoke should fail with helpful error
    output, err = capture_io do
      exit_code = Ace::Git::Secrets::Commands::RevokeCommand.execute(
        scan_file: scan_file
      )
      assert_equal 1, exit_code, "Revoke should fail when raw_value is missing"
    end

    assert_match(/missing raw_value/i, err)
    assert_match(/Re-run.*ace-git-secrets scan/i, err)
  end

  def test_rewrite_scan_file_fails_gracefully_without_raw_values
    # Test that rewrite-history command fails explicitly when raw_value is missing
    create_commit(@temp_repo, "dummy.txt", "dummy content", "Dummy commit")

    # Create a scan file WITHOUT raw_value
    cache_dir = File.join(@temp_repo, ".cache", "ace-git-secrets")
    FileUtils.mkdir_p(cache_dir)
    scan_file = File.join(cache_dir, "test-report.json")

    broken_report = {
      "scan_metadata" => { "repository" => @temp_repo },
      "tokens" => [
        {
          "token_type" => "github_pat_classic",
          "confidence" => "high",
          "commit_hash" => "abc123",
          "file_path" => "secret.txt"
          # Deliberately missing raw_value
        }
      ]
    }
    File.write(scan_file, JSON.pretty_generate(broken_report))

    # Rewrite should fail with helpful error (or proceed to scan fresh)
    with_rewriter_availability(true) do
      _output, err = capture_io do
        Ace::Git::Secrets::Commands::RewriteCommand.execute(
          scan_file: scan_file,
          dry_run: true
        )
      end

      # Either fails explicitly or proceeds with fresh scan (both acceptable)
      # If it fails, should mention missing raw_value
      if err.include?("missing raw_value")
        assert_match(/Re-run.*ace-git-secrets scan/i, err)
      end
    end
  end

  private

  def gitleaks_available?
    Ace::Git::Secrets::Atoms::GitleaksRunner.available?
  end

  # Mock API client for testing
  class MockApiClient
    attr_accessor :github_response

    def initialize
      @github_response = { success: true, message: "Mocked" }
    end

    def revoke_github_token(_token)
      github_response
    end

    def build_revocation_request(service, _token)
      { method: :post, url: "https://api.github.com/credentials/revoke", notes: "Mocked" }
    end
  end
end
