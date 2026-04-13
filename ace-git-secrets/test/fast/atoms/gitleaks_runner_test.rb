# frozen_string_literal: true

require_relative "../../test_helper"

class GitleaksRunnerTest < GitSecretsTestCase
  def setup
    @runner = Ace::Git::Secrets::Atoms::GitleaksRunner.new
  end

  def test_build_command_returns_array
    cmd = @runner.send(:build_command, path: "/path/to/repo", no_git: false, since: nil, verbose: false, report_path: "/tmp/report.json")

    assert_kind_of Array, cmd, "build_command should return an array (not a string) to avoid shell injection"
  end

  def test_build_command_basic
    cmd = @runner.send(:build_command, path: "/path/to/repo", no_git: false, since: nil, verbose: false, report_path: "/tmp/report.json")

    assert_equal "gitleaks", cmd[0]
    assert_equal "git", cmd[1]  # Uses 'git' subcommand for history scanning
    assert_includes cmd, "/path/to/repo"
    assert_includes cmd, "--report-format=json"
    assert cmd.any? { |part| part.start_with?("--report-path=") }
  end

  def test_build_command_with_no_git
    cmd = @runner.send(:build_command, path: "/path/to/repo", no_git: true, since: nil, verbose: false, report_path: "/tmp/report.json")

    assert_includes cmd, "--no-git"
    assert_equal "detect", cmd[1]  # Uses 'detect' subcommand for file-only scanning
  end

  def test_build_command_with_since
    cmd = @runner.send(:build_command, path: "/path/to/repo", no_git: false, since: "2024-01-01", verbose: false, report_path: "/tmp/report.json")

    assert_includes cmd, "--log-opts=--since=2024-01-01"
  end

  def test_build_command_with_verbose
    cmd = @runner.send(:build_command, path: "/path/to/repo", no_git: false, since: nil, verbose: true, report_path: "/tmp/report.json")

    assert_includes cmd, "--verbose"
  end

  def test_build_command_with_config_path
    runner = Ace::Git::Secrets::Atoms::GitleaksRunner.new(config_path: "/custom/config.toml")
    cmd = runner.send(:build_command, path: "/path/to/repo", no_git: false, since: nil, verbose: false, report_path: "/tmp/report.json")

    assert_includes cmd, "--config"
    assert_includes cmd, "/custom/config.toml"
  end

  def test_build_command_path_with_spaces_is_safe
    # This is the key security test - paths with spaces should not cause shell injection
    path_with_spaces = "/path/with spaces/and special; chars"
    cmd = @runner.send(:build_command, path: path_with_spaces, no_git: false, since: nil, verbose: false, report_path: "/tmp/report.json")

    # The path should be a separate array element, not concatenated
    assert_includes cmd, path_with_spaces
  end

  def test_run_gitleaks_returns_skipped_when_not_available
    runner = Ace::Git::Secrets::Atoms::GitleaksRunner.new

    # Stub available? to return false
    runner.stub :available?, false do
      result = runner.send(:run_gitleaks, path: ".", no_git: false, since: nil, verbose: false)

      assert_equal false, result[:success]
      assert_equal true, result[:skipped]
      assert_match(/not installed/, result[:message])
    end
  end

  # Simple struct to mock Process::Status
  FakeStatus = Struct.new(:exitstatus)

  def test_parse_results_clean
    status = FakeStatus.new(0)

    result = @runner.send(:parse_results, "", "", status)

    assert result[:success]
    assert result[:clean]
    refute result[:skipped]
    assert_empty result[:findings]
  end

  def test_parse_results_with_findings
    status = FakeStatus.new(1)

    json_output = <<~JSON
      [
        {
          "RuleID": "github-pat",
          "Secret": "ghp_test123",
          "File": "config.yml",
          "StartLine": 10,
          "Commit": "abc123",
          "Description": "GitHub Personal Access Token"
        }
      ]
    JSON

    result = @runner.send(:parse_results, json_output, "", status)

    assert result[:success]
    refute result[:clean]
    assert_equal 1, result[:findings].size
    assert_equal "github-pat", result[:findings].first[:pattern_name]
    assert_equal "ghp_test123", result[:findings].first[:matched_value]
  end

  def test_normalize_finding
    finding = {
      "RuleID" => "github-pat",
      "Secret" => "ghp_secret",
      "File" => "test.rb",
      "StartLine" => 42,
      "Commit" => "abc123def",
      "Description" => "GitHub PAT detected"
    }

    normalized = @runner.send(:normalize_finding, finding)

    assert_equal "github-pat", normalized[:pattern_name]
    assert_equal "github-pat", normalized[:token_type]
    assert_equal "high", normalized[:confidence]
    assert_equal "ghp_secret", normalized[:matched_value]
    assert_equal "test.rb", normalized[:file_path]
    assert_equal 42, normalized[:line_number]
    assert_equal "abc123def", normalized[:commit_hash]
    assert_equal "GitHub PAT detected", normalized[:description]
  end

  def test_ensure_available_raises_when_not_found
    klass = Ace::Git::Secrets::Atoms::GitleaksRunner

    klass.stub :available?, false do
      error = assert_raises(klass::GitleaksNotFoundError) do
        klass.ensure_available!
      end

      assert_match(/gitleaks is required/, error.message)
      assert_match(/brew install gitleaks/, error.message)
    end
  end

  def test_ensure_available_succeeds_when_found
    klass = Ace::Git::Secrets::Atoms::GitleaksRunner

    klass.stub :available?, true do
      # Should not raise
      klass.ensure_available!
    end
  end

  def test_class_available_method
    klass = Ace::Git::Secrets::Atoms::GitleaksRunner

    # Just verify it's callable and returns a boolean
    result = klass.available?
    assert [true, false].include?(result)
  end
end
