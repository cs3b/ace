# frozen_string_literal: true

require_relative "../test_helper"

class SecurityAuditorTest < GitSecretsTestCase
  def setup
    # Use mock repo for fast tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
  end

  def teardown
    @mock_repo&.cleanup
  end

  def test_whitelist_filters_by_file_pattern
    # Create test directory and file with token (no git subprocess)
    @mock_repo.add_file("test/mock_tokens.json", '{"token": "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB"}')

    whitelist = [
      {"file" => "test/*", "reason" => "Test fixtures"}
    ]

    # Mock gitleaks to return a finding for this file
    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB",
        file_path: "test/mock_tokens.json",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path,
        whitelist: whitelist
      )
      report = auditor.audit

      assert report.clean?, "Whitelisted file pattern should filter out token"
    end
  end

  def test_whitelist_filters_by_exact_token
    @mock_repo.add_file("config.txt", "API_KEY=ghp_test_example_for_documentation_only")

    whitelist = [
      {"pattern" => "ghp_test_example_for_documentation_only", "reason" => "Example token for docs"}
    ]

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_test_example_for_documentation_only",
        file_path: "config.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path,
        whitelist: whitelist
      )
      report = auditor.audit

      assert report.clean?, "Whitelisted exact token should be filtered"
    end
  end

  def test_whitelist_does_not_filter_non_matching_tokens
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_RealSecretToken1234567890ABCDEFGH")

    whitelist = [
      {"file" => "test/*", "reason" => "Test fixtures"}
    ]

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_RealSecretToken1234567890ABCDEFGH",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path,
        whitelist: whitelist
      )
      report = auditor.audit

      refute report.clean?, "Non-whitelisted token should still be detected"
      assert report.tokens.size >= 1, "Should detect at least one token"
    end
  end

  def test_audit_without_whitelist
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_SecretToken1234567890ABCDEFGHIJKL")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_SecretToken1234567890ABCDEFGHIJKL",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path
      )
      report = auditor.audit

      refute report.clean?
      assert report.tokens.size >= 1
    end
  end

  def test_audit_with_empty_whitelist
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_SecretToken1234567890ABCDEFGHIJKL")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_SecretToken1234567890ABCDEFGHIJKL",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path,
        whitelist: []
      )
      report = auditor.audit

      refute report.clean?, "Empty whitelist should not filter anything"
    end
  end

  def test_multiple_whitelist_rules
    # Create files in different locations
    @mock_repo.add_file("test/fixture.json", "ghp_TestFixtureTokenABCDEFGHIJKLMNOPQRSTUVWXYZ")
    @mock_repo.add_file("docs/example.md", "ghp_DocumentationExampleTokenABCDEFGHIJKLMNOPQ")
    @mock_repo.add_file("src/real.rb", "ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12")

    whitelist = [
      {"file" => "test/*", "reason" => "Test fixtures"},
      {"file" => "docs/*", "reason" => "Documentation examples"}
    ]

    # Mock gitleaks to return findings for all three files
    mock_findings = [
      {pattern_name: "github-pat", matched_value: "ghp_TestFixtureTokenABCDEFGHIJKLMNOPQRSTUVWXYZ", file_path: "test/fixture.json", commit_hash: "abc1234"},
      {pattern_name: "github-pat", matched_value: "ghp_DocumentationExampleTokenABCDEFGHIJKLMNOPQ", file_path: "docs/example.md", commit_hash: "abc1234"},
      {pattern_name: "github-pat", matched_value: "ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12", file_path: "src/real.rb", commit_hash: "abc1234"}
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
        repository_path: @mock_repo.path,
        whitelist: whitelist
      )
      report = auditor.audit

      # Only src/real.rb token should be detected (others whitelisted)
      refute report.clean?
      assert_equal 1, report.tokens.size, "Should detect exactly one token (the non-whitelisted one)"
      assert report.tokens.any? { |t| t.file_path.include?("src/real.rb") }, "Should detect token in src/real.rb"
    end
  end
end
