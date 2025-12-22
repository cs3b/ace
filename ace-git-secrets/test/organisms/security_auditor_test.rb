# frozen_string_literal: true

require_relative "../test_helper"

class SecurityAuditorTest < GitSecretsTestCase
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

  def test_whitelist_filters_by_file_pattern
    # Create test directory and file with token
    FileUtils.mkdir_p("test")
    File.write("test/mock_tokens.json", '{"token": "ghp_1234567890abcdefghijklmnopqrstuvwxyzAB"}')
    system("git add test/mock_tokens.json")
    system("git commit -q -m 'Test fixture'")

    whitelist = [
      { "file" => "test/*", "reason" => "Test fixtures" }
    ]

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo,
      whitelist: whitelist
    )
    report = auditor.audit

    assert report.clean?, "Whitelisted file pattern should filter out token"
  end

  def test_whitelist_filters_by_exact_token
    # Create file with known test token
    File.write("config.txt", "API_KEY=ghp_test_example_for_documentation_only")
    system("git add config.txt")
    system("git commit -q -m 'Add config'")

    whitelist = [
      { "pattern" => "ghp_test_example_for_documentation_only", "reason" => "Example token for docs" }
    ]

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo,
      whitelist: whitelist
    )
    report = auditor.audit

    assert report.clean?, "Whitelisted exact token should be filtered"
  end

  def test_whitelist_does_not_filter_non_matching_tokens
    # Create file with token not in whitelist
    # Use a high-entropy token that gitleaks will detect
    File.write("secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4")
    system("git add secret.txt")
    system("git commit -q -m 'Add secret'")

    whitelist = [
      { "file" => "test/*", "reason" => "Test fixtures" }
    ]

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo,
      whitelist: whitelist
    )
    report = auditor.audit

    refute report.clean?, "Non-whitelisted token should still be detected"
    assert report.tokens.size >= 1, "Should detect at least one token"
  end

  def test_audit_without_whitelist
    # Use a high-entropy token that gitleaks will detect
    File.write("secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4")
    system("git add secret.txt")
    system("git commit -q -m 'Add secret'")

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo
    )
    report = auditor.audit

    refute report.clean?
    assert report.tokens.size >= 1
  end

  def test_audit_with_empty_whitelist
    # Use a high-entropy token that gitleaks will detect
    File.write("secret.txt", "TOKEN=ghp_x9K2mNpL4qR7sT1vW5yZ8bC3dE6fG0hI2jK4")
    system("git add secret.txt")
    system("git commit -q -m 'Add secret'")

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo,
      whitelist: []
    )
    report = auditor.audit

    refute report.clean?, "Empty whitelist should not filter anything"
  end

  def test_multiple_whitelist_rules
    # Create files in different locations (ghp_ + 36+ alphanumeric chars)
    FileUtils.mkdir_p("test")
    FileUtils.mkdir_p("docs")
    FileUtils.mkdir_p("src")
    File.write("test/fixture.json", "ghp_TestFixtureTokenABCDEFGHIJKLMNOPQRSTUVWXYZ")
    File.write("docs/example.md", "ghp_DocumentationExampleTokenABCDEFGHIJKLMNOPQ")
    File.write("src/real.rb", "ghp_RealSecretTokenABCDEFGHIJKLMNOPQRSTUVWXYZ12")
    system("git add .")
    system("git commit -q -m 'Add files'")

    whitelist = [
      { "file" => "test/*", "reason" => "Test fixtures" },
      { "file" => "docs/*", "reason" => "Documentation examples" }
    ]

    auditor = Ace::Git::Secrets::Organisms::SecurityAuditor.new(
      repository_path: @temp_repo,
      whitelist: whitelist
    )
    report = auditor.audit

    # Only src/real.rb token should be detected
    refute report.clean?
    assert report.tokens.size >= 1, "Should detect at least one token"
    assert report.tokens.any? { |t| t.file_path.include?("src/real.rb") }, "Should detect token in src/real.rb"
  end

  private

  def gitleaks_available?
    Ace::Git::Secrets::Atoms::GitleaksRunner.available?
  end
end
