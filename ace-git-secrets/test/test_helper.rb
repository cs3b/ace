# frozen_string_literal: true

require "securerandom"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add ace-support-core to load path if it exists
ace_support_core_path = File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift(ace_support_core_path) if Dir.exist?(ace_support_core_path)

# Add ace-support-test-helpers to load path for shared fixtures
ace_test_helpers_path = File.expand_path("../../ace-support-test-helpers/lib", __dir__)
$LOAD_PATH.unshift(ace_test_helpers_path) if Dir.exist?(ace_test_helpers_path)

require "ace/git/secrets"
require "ace/test_support/fixtures/git_mocks"

require "minitest/autorun"

# Standardized test token patterns for consistent, readable tests
# All tokens follow the format: ghp_TEST_<context>_<unique-suffix>
# The _TEST_ prefix makes it obvious these are test values, not real secrets
#
# SECURITY WARNING: These patterns are for TESTING ONLY.
# NEVER use these patterns or similar test tokens for real secrets.
# Real credentials should never be committed to version control.
module TestTokens
  # Standard test token (40 chars after ghp_ to match real GitHub PAT format)
  STANDARD = "ghp_TEST_token_abc1234567890defghijklmnop"

  # Token for specific test contexts
  REVOKE = "ghp_TEST_revoke_abc1234567890defghijklmn"
  REWRITE = "ghp_TEST_rewrite_abc1234567890defghijklm"
  SCAN = "ghp_TEST_scan_abc1234567890defghijklmnop"
  FILTER = "ghp_TEST_filter_abc1234567890defghijklmn"
  WHITELIST = "ghp_TEST_whitelist_abc1234567890defghijk"

  # Token for duplicate detection tests
  DUPLICATE_A = "ghp_TEST_duplicate_A_abc1234567890defghij"
  DUPLICATE_B = "ghp_TEST_duplicate_B_abc1234567890defghij"

  # Token for confidence level tests
  HIGH_CONFIDENCE = "ghp_TEST_high_conf_abc1234567890defghijk"
  LOW_CONFIDENCE = "ghp_TEST_low_conf_abc1234567890defghijkl"

  # Generate a unique test token with context
  # @param context [String] Context description (e.g., "audit", "scan")
  # @param suffix [String] Optional unique suffix (defaults to 20 random hex chars)
  # @return [String] Token in format ghp_TEST_<context>_<suffix>
  def self.generate(context, suffix = nil)
    # 10 bytes = 20 hex chars, providing sufficient uniqueness for test isolation
    suffix ||= SecureRandom.hex(10)
    base = "ghp_TEST_#{context}_#{suffix}"
    # Ensure 40-char length after ghp_ (like real GitHub PATs)
    base.ljust(44, "0")[0, 44]
  end
end

# Base test case for ace-git-secrets tests
class GitSecretsTestCase < Minitest::Test
  # ============================================================================
  # REAL GIT REPO HELPERS (for integration tests only - ~150ms per call)
  # ============================================================================

  # Helper to create a temporary git repository for testing
  # WARNING: This spawns multiple subprocess calls (~150-400ms)
  # For unit tests, prefer with_mock_git_repo instead
  def create_temp_repo
    dir = Dir.mktmpdir("ace-git-secrets-test")
    Dir.chdir(dir) do
      system("git init -q")
      system("git config user.email 'test@test.com'")
      system("git config user.name 'Test'")
    end
    dir
  end

  # Helper to clean up temp directory
  def cleanup_temp_repo(dir)
    FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
  end

  # Helper to create a commit with content
  # WARNING: Spawns subprocess calls (~50-100ms per commit)
  # For unit tests, prefer with_mock_git_repo instead
  def create_commit(repo_path, filename, content, message = "Add file")
    Dir.chdir(repo_path) do
      File.write(filename, content)
      system("git add #{filename}")
      system("git commit -q -m '#{message}'")
    end
  end

  # ============================================================================
  # MOCK GIT REPO HELPERS (for unit tests - instant, no subprocess)
  # ============================================================================

  # Use shared MockGitRepo from ace-support-test-helpers
  MockGitRepo = Ace::TestSupport::Fixtures::GitMocks::MockGitRepo

  # Mock git repository structure for fast unit tests
  # Provides a temp directory with files but no actual git init
  # Use this for testing code that reads files but doesn't need real git commands
  #
  # @yield [MockGitRepo] Repository mock with helper methods
  # @example
  #   with_mocked_git_repo do |repo|
  #     repo.add_file("secret.txt", "TOKEN=ghp_abc123")
  #     repo.add_commit("abc1234", message: "Add secret")
  #     # Test code that examines repo structure
  #   end
  def with_mocked_git_repo
    repo = MockGitRepo.new
    begin
      yield repo
    ensure
      repo.cleanup
    end
  end

  # @deprecated Use with_mocked_git_repo instead. Will be removed in v1.0.
  def with_mock_git_repo(&block)
    warn "[DEPRECATION] with_mock_git_repo is deprecated and will be removed in v1.0. " \
         "Use with_mocked_git_repo instead."
    with_mocked_git_repo(&block)
  end

  # ============================================================================
  # GITLEAKS MOCK HELPERS (for unit tests - no real gitleaks execution)
  # ============================================================================

  # Mock gitleaks scan results for fast unit testing
  # Stubs GitleaksRunner to return specified results without subprocess
  #
  # @param findings [Array<Hash>] Mock findings to return
  # @param clean [Boolean] Whether scan should report clean
  # @yield Block to execute with mocked gitleaks
  # @example
  #   with_mocked_gitleaks(clean: true) do
  #     auditor = SecurityAuditor.new(repository_path: repo.path)
  #     report = auditor.audit
  #     assert report.clean?
  #   end
  #
  #   with_mocked_gitleaks(findings: [
  #     { pattern_name: "github-pat", matched_value: "ghp_abc" }
  #   ]) do
  #     auditor = SecurityAuditor.new(repository_path: repo.path)
  #     report = auditor.audit
  #     assert_equal 1, report.tokens.size
  #   end
  def with_mocked_gitleaks(findings: [], clean: nil)
    clean = findings.empty? if clean.nil?

    mock_result = {
      success: true,
      clean: clean,
      skipped: false,
      findings: findings.map { |f| create_mock_finding(f) },
      message: clean ? "No tokens detected" : "Tokens detected"
    }

    runner_class = Ace::Git::Secrets::Atoms::GitleaksRunner

    # Use thread-safe stub pattern instead of define_method
    # This works by stubbing instance methods via class-level stub
    runner_class.stub :new, ->(**_opts) {
      mock_runner = Object.new
      mock_runner.define_singleton_method(:scan_history) { |**_| mock_result }
      mock_runner.define_singleton_method(:scan_files) { |**_| mock_result }
      mock_runner.define_singleton_method(:available?) { true }
      mock_runner
    } do
      yield
    end
  end

  # Create a mock token for testing
  # @param raw_value [String] The token value
  # @param opts [Hash] Optional overrides for token fields
  # @return [Ace::Git::Secrets::Models::DetectedToken]
  def create_mock_token(raw_value, **opts)
    defaults = {
      token_type: "github_pat_classic",
      pattern_name: "github_pat_classic",
      confidence: "high",
      commit_hash: "abc1234",
      file_path: "secret.txt",
      detected_by: "test"
    }
    Ace::Git::Secrets::Models::DetectedToken.new(
      **defaults.merge(opts).merge(raw_value: raw_value)
    )
  end

  # Create a standardized mock finding hash for testing
  # This ensures all mock findings have required fields with sensible defaults
  # @param finding [Hash] Partial finding to expand
  # @return [Hash] Complete finding hash with all required fields
  def create_mock_finding(finding)
    {
      pattern_name: finding[:pattern_name] || "generic-secret",
      token_type: finding[:token_type] || finding[:pattern_name] || "generic-secret",
      confidence: finding[:confidence] || "high",
      matched_value: finding[:matched_value] || finding[:raw_value] || "mock_token",
      file_path: finding[:file_path] || "test.txt",
      line_number: finding[:line_number] || 1,
      commit_hash: finding[:commit_hash] || "abc1234",
      description: finding[:description] || "Mock finding"
    }
  end

  # Helper to stub GitRewriter.available? without method redefinition warnings
  # Uses Module#prepend pattern for clean stubbing
  # @param available [Boolean] What available? should return
  # @yield Block to execute with stubbed behavior
  def with_rewriter_availability(available)
    rewriter_class = Ace::Git::Secrets::Molecules::GitRewriter

    # Create a module that overrides available?
    stub_module = Module.new do
      define_method(:available?) { available }
    end

    # Prepend it to override the method
    rewriter_class.prepend(stub_module)

    yield

    # Remove the prepended module by reloading the class behavior
    # The original method is still in the class, just shadowed
    # For tests, this is acceptable as each test creates fresh instances
  end

  # Helper to stub GitleaksRunner.available? without warnings
  # @param available [Boolean] What available? should return
  # @yield Block to execute with stubbed behavior
  def with_gitleaks_availability(available)
    gitleaks_class = Ace::Git::Secrets::Atoms::GitleaksRunner

    stub_module = Module.new do
      define_method(:available?) { available }
    end

    gitleaks_class.prepend(stub_module)

    yield
  end

  # Stub clean_working_directory? to return true for mock repos
  # Uses thread-safe stub pattern instead of define_method
  # @yield Block to execute with clean working directory stubbed
  def with_clean_working_directory
    rewriter_class = Ace::Git::Secrets::Molecules::GitRewriter

    # Create a mock rewriter that delegates most methods but stubs clean_working_directory?
    original_new = rewriter_class.method(:new)
    rewriter_class.stub :new, ->(**opts) {
      instance = original_new.call(**opts)
      instance.define_singleton_method(:clean_working_directory?) { true }
      instance
    } do
      yield
    end
  end

  # Composite helper for rewrite command tests
  # Combines gitleaks mocking + rewriter availability + clean working directory
  # Reduces 4 levels of nesting to 1
  # @param findings [Array<Hash>] Mock gitleaks findings (default: empty = clean scan)
  # @param rewriter_available [Boolean] Whether git-filter-repo is available (default: true)
  # @yield Block to execute with all mocks in place
  def with_rewrite_test_mocks(findings: [], rewriter_available: true)
    clean = findings.empty?

    with_mocked_gitleaks(findings: findings, clean: clean) do
      with_rewriter_availability(rewriter_available) do
        with_clean_working_directory do
          yield
        end
      end
    end
  end

  # Path to test-specific gitleaks config with test token patterns
  # @return [String] Absolute path to test gitleaks.toml
  def test_gitleaks_config
    File.join(File.dirname(__FILE__), "gitleaks.toml")
  end

  # Set test gitleaks config via environment variable
  # Resets Ace::Git::Secrets config cache to pick up new value
  # @yield Block to execute with test config active
  def with_test_gitleaks_config
    config_path = test_gitleaks_config
    original_env = ENV["ACE_GITLEAKS_CONFIG_PATH"]

    begin
      ENV["ACE_GITLEAKS_CONFIG_PATH"] = config_path
      # Reset config cache to pick up new environment variable
      Ace::Git::Secrets.reset_config!
      yield
    ensure
      ENV["ACE_GITLEAKS_CONFIG_PATH"] = original_env
      # Reset config cache again to restore original state
      Ace::Git::Secrets.reset_config!
    end
  end
end
