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

# Base test class
class AceReviewTest < Minitest::Test
  def setup
    @original_pwd = Dir.pwd
    @test_dir = Dir.mktmpdir("ace-review-test")
    Dir.chdir(@test_dir)

    # Stub ace-context to prevent expensive shell command execution during tests
    stub_ace_context
    # Stub git-extractor to prevent expensive git command execution during tests
    stub_git_extractor
  end

  def teardown
    # Restore original ace-context and git-extractor methods
    restore_ace_context
    restore_git_extractor

    Dir.chdir(@original_pwd)
    FileUtils.remove_entry(@test_dir)
  end

  # Stub Ace::Context.load_file and load_auto to return fast mock data instead of executing commands
  def stub_ace_context
    return unless defined?(Ace::Context)

    # Use shared fixtures from ace-support-test-helpers
    @original_context_methods = {}
    Ace::TestSupport::Fixtures::ContextMocks.stub_load_file(@original_context_methods)
    Ace::TestSupport::Fixtures::ContextMocks.stub_load_auto(@original_context_methods)
  end

  # Restore original Ace::Context.load_file and load_auto methods
  def restore_ace_context
    return unless @original_context_methods

    Ace::TestSupport::Fixtures::ContextMocks.restore_load_file(@original_context_methods)
    Ace::TestSupport::Fixtures::ContextMocks.restore_load_auto(@original_context_methods)
  end

  # Stub Ace::Context::Atoms::GitExtractor to prevent expensive git command execution
  def stub_git_extractor
    return unless defined?(Ace::Context::Atoms::GitExtractor)

    # Use shared fixtures from ace-support-test-helpers
    @original_git_methods = {}
    Ace::TestSupport::Fixtures::ContextMocks.stub_git_extractor(@original_git_methods)
  end

  # Restore original GitExtractor methods
  def restore_git_extractor
    return unless @original_git_methods

    Ace::TestSupport::Fixtures::ContextMocks.restore_git_extractor(@original_git_methods)
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