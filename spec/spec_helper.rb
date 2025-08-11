# frozen_string_literal: true

# SimpleCov must be loaded before application code
require "simplecov"
require "simplecov-html"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/.bundle/"

  add_group "Library", "lib"
  add_group "Claude Commands", "lib/coding_agent_tools/cli/commands/handbook/claude"
  add_group "Claude Organisms", "lib/coding_agent_tools/organisms/claude"

  # Set coverage thresholds but don't fail build for now
  # Will be increased as test coverage improves
  minimum_coverage 0
  minimum_coverage_by_file 0

  # HTML formatter for coverage reports
  formatter SimpleCov::Formatter::HTMLFormatter

  track_files "lib/**/*.rb"
end

require "coding_agent_tools"
require "rspec/temp_dir"

# Load environment helper first (sets up API keys, etc.)
require_relative "support/env_helper"

# Load VCR configuration
require_relative "support/vcr"

# Load test reliability tracker
require_relative "support/test_reliability_tracker"

# Load custom matchers
require_relative "support/matchers/json_matchers"
require_relative "support/matchers/http_matchers"

# Load shared helpers
require_relative "support/process_helpers"
# CLI helpers for direct command invocation (performance optimization)
require_relative "support/cli_helpers"
# Helper for safe ENV manipulation in specs
require_relative "support/env_helpers"
# ANSI color testing infrastructure
require_relative "support/ansi_color_testing_helper"
# Prevent interactive prompts in tests
require_relative "support/file_operation_confirmer_helper"
# Mock helpers for consistent external dependency mocking
require_relative "support/mock_helpers"
# Test factories for creating complex test data structures
require_relative "support/test_factories"

# Load shared examples for client behaviors
require_relative "support/shared_examples/client_behavior"

# Helper method for safe directory cleanup to prevent getcwd errors
def safe_directory_cleanup(temp_dir)
  return unless temp_dir && File.exist?(temp_dir)

  # Ensure we're not inside the directory we're about to delete
  original_dir = Dir.pwd
  if original_dir.start_with?(File.realpath(temp_dir))
    # Move to a safe directory (parent of temp dir or project root)
    safe_dir = File.dirname(temp_dir)
    safe_dir = ENV["PROJECT_ROOT"] || Dir.home if !Dir.exist?(safe_dir)
    Dir.chdir(safe_dir) if Dir.exist?(safe_dir)
  end

  # Remove the directory
  FileUtils.remove_entry(temp_dir)
rescue Errno::ENOENT, Errno::ENOTDIR
  # Directory already removed or doesn't exist
rescue => e
  # Log but don't fail on cleanup errors
  warn "Warning: Failed to cleanup directory #{temp_dir}: #{e.message}" unless ENV["CI"]
end

RSpec.configure do |config|
  # Skip VCR tests in Ruby 3.4.2+ due to compatibility issues
  # See: https://github.com/vcr/vcr/issues/XXX (VCR method interception conflicts with Ruby 3.4.2)
  if RUBY_VERSION >= "3.4.0"
    config.filter_run_excluding :vcr
    puts "Skipping VCR tests due to Ruby #{RUBY_VERSION} compatibility issues" unless ENV["CI"]
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Configure rspec-temp_dir for isolated temporary directories
  # (Uses shared contexts instead of include)

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure mocks for better test safety
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true  # Verify that mocked methods exist
    mocks.verify_doubled_constant_names = true  # Verify that doubled constants exist
  end

  # Silence application output during tests
  config.before(:example) do |example|
    # Allow verbose output for specific tests or when debugging
    next if example.metadata[:verbose] || ENV["VERBOSE"] == "true" || ENV["DEBUG"] == "true"

    # Suppress all command output by default
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
    allow($stderr).to receive(:puts)
    allow($stderr).to receive(:print)
  end

  # Include helper modules in all examples
  config.include MockHelpers
  config.include TestFactories

  # Additional RSpec best practices configuration
  config.order = :random  # Run specs in random order to surface order dependencies
  config.warnings = false  # Suppress Ruby warnings during tests
  config.profile_examples = 5 if ENV["PROFILE"] == "true"  # Show slowest examples when profiling

  # Prevent environment variable leakage, output pollution, and working directory changes between examples
  config.around do |example|
    original_env = ENV.to_hash
    original_dir = Dir.pwd
    original_stdout = $stdout
    original_stderr = $stderr

    # Ensure tests run in CI mode to prevent interactive prompts
    # But allow VCR recording when explicitly requested via VCR_RECORD
    ENV["CI"] = "true" unless ENV.key?("CI") || ENV["VCR_RECORD"]

    # Set PROJECT_ROOT to prevent project root detection failures in tests
    # Point to the actual project root (handbook-meta) which contains the submodules
    unless ENV["PROJECT_ROOT"]
      ENV["PROJECT_ROOT"] = File.expand_path("../../..", __dir__)
    end

    # Capture stdout/stderr to prevent test output pollution
    # unless running with DEBUG=true or specific verbose flags
    unless ENV["DEBUG"] == "true" || ENV["VERBOSE"] == "true" || example.metadata[:verbose]
      require "stringio"
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    # Run the example with retry logic for flaky tests
    retries = example.metadata[:retry] || 0
    retry_count = 0

    begin
      example.run
    rescue => e
      if retry_count < retries && !ENV["CI"]
        retry_count += 1
        warn "\nRetrying flaky test (attempt #{retry_count + 1}/#{retries + 1}): #{example.full_description}"
        example.reset!
        retry
      else
        raise e
      end
    end
  ensure
    # Restore streams
    $stdout = original_stdout
    $stderr = original_stderr

    # Restore environment and working directory
    ENV.replace(original_env)

    # Safely restore working directory - only if original directory still exists
    # and we're not already in it
    if Dir.pwd != original_dir && Dir.exist?(original_dir)
      begin
        Dir.chdir(original_dir)
      rescue Errno::ENOENT
        # Original directory no longer exists, stay where we are
        # This can happen when tests delete directories
      end
    end
  end

  # Suppress application warnings and logging during tests to keep output clean
  config.before(:suite) do
    # Suppress directory navigator warnings
    require_relative "../lib/coding_agent_tools/atoms/taskflow_management/directory_navigator"
    CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator.suppress_warnings = true

    # Suppress security logger output during tests
    require_relative "../lib/coding_agent_tools/atoms/security_logger"
    CodingAgentTools::Atoms::SecurityLogger.suppress_output = true
  rescue LoadError
    # Components not available, continue without suppression
  end

  config.after(:suite) do
    # Ensure we're in a safe directory before final cleanup
    begin
      safe_dir = ENV["PROJECT_ROOT"] || File.expand_path("../../..", __dir__)
      Dir.chdir(safe_dir) if Dir.exist?(safe_dir) && Dir.pwd != safe_dir
    rescue
      # Ignore errors during final directory cleanup
    end

    # Restore warning behavior after test suite completes
    CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator.suppress_warnings = false
    CodingAgentTools::Atoms::SecurityLogger.suppress_output = false
  rescue NameError
    # Components not available, no action needed
  end
end
