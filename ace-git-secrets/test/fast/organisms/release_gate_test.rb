# frozen_string_literal: true

require_relative "../../test_helper"

class ReleaseGateTest < GitSecretsTestCase
  def setup
    # Use mock repo for fast tests - no real git subprocess calls
    @mock_repo = MockGitRepo.new
  end

  def teardown
    @mock_repo&.cleanup
  end

  def test_check_passes_with_clean_repository
    @mock_repo.add_file("readme.md", "# My Project\n\nThis is a clean file.")

    # Mock gitleaks to return clean scan
    with_mocked_gitleaks(clean: true) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check

      assert result[:passed], "Clean repository should pass release gate"
      assert_equal 0, result[:exit_code]
      assert_match(/PASSED/, result[:message])
      assert_match(/No authentication tokens detected/, result[:summary])
    end
  end

  def test_check_fails_with_tokens_in_history
    @mock_repo.add_file("config.txt", "TOKEN=ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12",
        file_path: "config.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check

      refute result[:passed], "Repository with tokens should fail release gate"
      assert_equal 1, result[:exit_code]
      assert_match(/FAILED/, result[:message])
      assert_match(/authentication token/, result[:summary])
      assert result[:remediation], "Should include remediation steps"
    end
  end

  def test_strict_mode_configuration
    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @mock_repo.path,
      strict: true
    )
    assert gate.strict_mode

    gate_non_strict = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @mock_repo.path,
      strict: false
    )
    refute gate_non_strict.strict_mode
  end

  def test_format_result_as_table
    @mock_repo.add_file("readme.md", "Clean content")

    with_mocked_gitleaks(clean: true) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check
      output = gate.format_result(result, format: "table")

      assert_includes output, "="
      assert_includes output, "PASSED"
    end
  end

  def test_format_result_as_json
    @mock_repo.add_file("readme.md", "Clean content")

    with_mocked_gitleaks(clean: true) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check
      output = gate.format_result(result, format: "json")

      parsed = JSON.parse(output)
      assert parsed["passed"]
      assert_equal 0, parsed["token_count"]
    end
  end

  def test_failure_summary_includes_token_info
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check

      # Check for token count in summary
      assert_match(/authentication token.*detected/i, result[:summary])
    end
  end

  def test_remediation_steps_include_commands
    @mock_repo.add_file("secret.txt", "TOKEN=ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ")

    mock_findings = [
      {
        pattern_name: "github-pat",
        matched_value: "ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ",
        file_path: "secret.txt",
        commit_hash: "abc1234"
      }
    ]

    with_mocked_gitleaks(findings: mock_findings) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check

      assert_includes result[:remediation], "ace-git-secrets scan"
      assert_includes result[:remediation], "ace-git-secrets revoke"
      assert_includes result[:remediation], "ace-git-secrets rewrite-history"
      assert_includes result[:remediation], "git push --force-with-lease"
    end
  end

  def test_report_accessible_from_result
    @mock_repo.add_file("readme.md", "Clean")

    with_mocked_gitleaks(clean: true) do
      gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
        repository_path: @mock_repo.path
      )
      result = gate.check

      assert result[:report].is_a?(Ace::Git::Secrets::Models::ScanReport)
      assert result[:report].clean?
    end
  end
end
