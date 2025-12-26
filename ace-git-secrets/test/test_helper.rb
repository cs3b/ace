# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add ace-support-core to load path if it exists
ace_support_core_path = File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift(ace_support_core_path) if Dir.exist?(ace_support_core_path)

require "ace/git/secrets"

require "minitest/autorun"

# Base test case for ace-git-secrets tests
class GitSecretsTestCase < Minitest::Test
  # Helper to create a temporary git repository for testing
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
  def create_commit(repo_path, filename, content, message = "Add file")
    Dir.chdir(repo_path) do
      File.write(filename, content)
      system("git add #{filename}")
      system("git commit -q -m '#{message}'")
    end
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
  ensure
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
