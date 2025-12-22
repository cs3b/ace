# frozen_string_literal: true

require_relative "../test_helper"

class ReleaseGateTest < GitSecretsTestCase
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

  def test_check_passes_with_clean_repository
    # Create a file without any tokens
    File.write("readme.md", "# My Project\n\nThis is a clean file.")
    system("git add readme.md")
    system("git commit -q -m 'Initial commit'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check

    assert result[:passed], "Clean repository should pass release gate"
    assert_equal 0, result[:exit_code]
    assert_match(/PASSED/, result[:message])
    assert_match(/No authentication tokens detected/, result[:summary])
  end

  def test_check_fails_with_tokens_in_history
    # Create file with a token (ghp_ + 36+ alphanumeric chars)
    File.write("config.txt", "TOKEN=ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12")
    system("git add config.txt")
    system("git commit -q -m 'Add config'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check

    refute result[:passed], "Repository with tokens should fail release gate"
    assert_equal 1, result[:exit_code]
    assert_match(/FAILED/, result[:message])
    assert_match(/authentication token/, result[:summary])
    assert result[:remediation], "Should include remediation steps"
  end

  def test_strict_mode_configuration
    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo,
      strict: true
    )
    assert gate.strict_mode

    gate_non_strict = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo,
      strict: false
    )
    refute gate_non_strict.strict_mode
  end

  def test_format_result_as_table
    File.write("readme.md", "Clean content")
    system("git add readme.md")
    system("git commit -q -m 'Initial'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check
    output = gate.format_result(result, format: "table")

    assert_includes output, "="
    assert_includes output, "PASSED"
  end

  def test_format_result_as_json
    File.write("readme.md", "Clean content")
    system("git add readme.md")
    system("git commit -q -m 'Initial'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check
    output = gate.format_result(result, format: "json")

    parsed = JSON.parse(output)
    assert parsed["passed"]
    assert_equal 0, parsed["token_count"]
  end

  def test_failure_summary_includes_token_info
    # Create file with GitHub token
    File.write("secret.txt", "TOKEN=ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ")
    system("git add secret.txt")
    system("git commit -q -m 'Add secret'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check

    # Check for token count in summary
    assert_match(/authentication token.*detected/i, result[:summary])
  end

  def test_remediation_steps_include_commands
    File.write("secret.txt", "TOKEN=ghp_GitHubPatClassicABCDEFGHIJKLMNOPQRSTUVWXYZ")
    system("git add secret.txt")
    system("git commit -q -m 'Add secret'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check

    assert_includes result[:remediation], "ace-git-secrets scan"
    assert_includes result[:remediation], "ace-git-secrets revoke"
    assert_includes result[:remediation], "ace-git-secrets rewrite-history"
    assert_includes result[:remediation], "git push --force-with-lease"
  end

  def test_report_accessible_from_result
    File.write("readme.md", "Clean")
    system("git add readme.md")
    system("git commit -q -m 'Initial'")

    gate = Ace::Git::Secrets::Organisms::ReleaseGate.new(
      repository_path: @temp_repo
    )
    result = gate.check

    assert result[:report].is_a?(Ace::Git::Secrets::Models::ScanReport)
    assert result[:report].clean?
  end

  private

  def gitleaks_available?
    Ace::Git::Secrets::Atoms::GitleaksRunner.available?
  end
end
