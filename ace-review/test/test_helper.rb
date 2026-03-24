# frozen_string_literal: true

# Standardized coverage configuration
if ENV["COVERAGE"]
  require "ace/test_support/coverage"
  Ace::TestSupport::Coverage.start("ace-review")
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/review"

require "minitest/autorun"
require "minitest/pride"

# Load shared test support for mocking fixtures
require "ace/test_support"

# Module providing shared temp directory functionality for test classes.
# Test classes can opt-in to share a temp directory across all tests in the class,
# reducing setup/teardown overhead from ~10ms per test to near-zero.
#
# Usage:
#   class MyTest < AceReviewTest
#     def self.use_shared_temp_dir?
#       true
#     end
#   end
module SharedTempDir
  # Track all shared temp dirs for cleanup at suite end
  @shared_temp_dirs = {}
  @mutex = Mutex.new

  class << self
    attr_reader :shared_temp_dirs, :mutex

    # Register a shared temp dir for a test class
    def register(klass, dir)
      mutex.synchronize { shared_temp_dirs[klass] = dir }
    end

    # Get the shared temp dir for a test class
    def get(klass)
      mutex.synchronize { shared_temp_dirs[klass] }
    end

    # Clean up all shared temp dirs
    def cleanup_all
      mutex.synchronize do
        shared_temp_dirs.each_value do |dir|
          FileUtils.remove_entry(dir) if dir && Dir.exist?(dir)
        end
        shared_temp_dirs.clear
      end
    end
  end

  # Returns the shared temp directory for this test class.
  # Creates the directory lazily on first call.
  def shared_test_dir
    existing = SharedTempDir.get(self.class)
    return existing if existing

    dir = Dir.mktmpdir("ace-review-shared-#{self.class.name&.gsub("::", "-") || "test"}")
    SharedTempDir.register(self.class, dir)
    dir
  end

  # Clear all files in the shared temp directory without removing the directory itself.
  # This is faster than recreating the directory.
  def clear_shared_test_dir
    dir = SharedTempDir.get(self.class)
    return unless dir && Dir.exist?(dir)

    Dir.children(dir).each do |child|
      FileUtils.remove_entry(File.join(dir, child))
    end
  end
end

# Register cleanup of shared temp dirs when test suite finishes
Minitest.after_run do
  SharedTempDir.cleanup_all
end

# Base test class
class AceReviewTest < Minitest::Test
  # Include shared prompt stubbing helpers from ace-support-test-helpers
  include Ace::TestSupport::Fixtures::PromptHelpers
  # Include shared temp dir functionality for opt-in performance optimization
  include SharedTempDir

  def setup
    @original_pwd = Dir.pwd

    # Check if test class opts into shared temp dir (reduces ~10ms overhead per test)
    if self.class.respond_to?(:use_shared_temp_dir?) && self.class.use_shared_temp_dir?
      @using_shared_temp_dir = true
      @test_dir = shared_test_dir
      clear_shared_test_dir
    else
      @using_shared_temp_dir = false
      @test_dir = Dir.mktmpdir("ace-review-test")
    end

    Dir.chdir(@test_dir)

    # Stub ace-bundle to prevent expensive shell command execution during tests
    stub_ace_bundle
    # Stub git operations to prevent expensive git command execution during tests
    stub_branch_reader
  end

  def teardown
    # Restore original ace-bundle and git methods
    restore_ace_bundle
    restore_branch_reader

    Dir.chdir(@original_pwd)

    # Only remove temp dir if not using shared mode
    # Shared temp dirs are cleaned up by Minitest.after_run
    unless @using_shared_temp_dir
      FileUtils.remove_entry(@test_dir)
    end
  end

  # Stub Ace::Bundle.load_file and load_auto to return fast mock data instead of executing commands
  def stub_ace_bundle
    return unless defined?(Ace::Bundle)

    # Use shared fixtures from ace-support-test-helpers
    @original_bundle_methods = {}
    Ace::TestSupport::Fixtures::BundleMocks.stub_load_file(@original_bundle_methods)
    Ace::TestSupport::Fixtures::BundleMocks.stub_load_auto(@original_bundle_methods)
  end

  # Restore original Ace::Bundle.load_file and load_auto methods
  def restore_ace_bundle
    return unless @original_bundle_methods

    Ace::TestSupport::Fixtures::BundleMocks.restore_load_file(@original_bundle_methods)
    Ace::TestSupport::Fixtures::BundleMocks.restore_load_auto(@original_bundle_methods)
  end

  # Stub Ace::Git::Molecules::BranchReader to prevent expensive git command execution
  def stub_branch_reader
    return unless defined?(Ace::Git::Molecules::BranchReader)

    @original_tracking_branch = Ace::Git::Molecules::BranchReader.method(:tracking_branch)
    Ace::Git::Molecules::BranchReader.define_singleton_method(:tracking_branch) do |executor: nil|
      "origin/main"
    end
  end

  # Restore original BranchReader methods
  def restore_branch_reader
    return unless @original_tracking_branch

    Ace::Git::Molecules::BranchReader.define_singleton_method(:tracking_branch, @original_tracking_branch)
  end

  # Helper to create a test configuration file
  def create_test_config(content = nil)
    FileUtils.mkdir_p(".ace/review")
    config_content = content || default_test_config
    File.write(".ace/review/config.yml", config_content)
  end

  # Helper to create a test preset file
  def create_test_preset(name, content)
    FileUtils.mkdir_p(".ace/review/presets")
    File.write(".ace/review/presets/#{name}.yml", content)
  end

  # Helper to create a mock ParseResult from ace-git
  # Provides consistent mock creation across tests, isolating from ace-git internal changes
  #
  # @param number [String, Integer] PR number
  # @param repo [String, nil] Repository in "owner/repo" format (nil for local-only PRs)
  # @param gh_format [String, nil] gh CLI format (defaults to repo#number or just number)
  # @return [Ace::Git::Atoms::PrIdentifierParser::ParseResult]
  def mock_parse_result(number:, repo: nil, gh_format: nil)
    gh_format ||= repo ? "#{repo}##{number}" : number.to_s
    Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
      number: number.to_s,
      repo: repo,
      gh_format: gh_format
    )
  end

  private

  def default_test_config
    <<~YAML
      defaults:
        model: "test-model"
        output_format: "markdown"
        context: "none"

      presets:
        test:
          description: "Test preset"
          prompt_composition:
            base: "prompt://base/system"
            format: "prompt://format/standard"
          context: "none"
          subject:
            commands:
              - "echo 'test diff'"
    YAML
  end
end
