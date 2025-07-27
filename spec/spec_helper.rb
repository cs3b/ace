# frozen_string_literal: true

# SimpleCov must be loaded before application code
require "simplecov"
require "simplecov-html"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/.bundle/"

  add_group "Library", "lib"

  # Set coverage thresholds but don't fail build for now
  # Will be increased as test coverage improves
  minimum_coverage 0
  minimum_coverage_by_file 0

  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter
  ])

  track_files "lib/**/*.rb"
end

require "coding_agent_tools"

# Load environment helper first (sets up API keys, etc.)
require_relative "support/env_helper"

# Load VCR configuration
require_relative "support/vcr"

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

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include helper modules in all examples
  config.include MockHelpers
  config.include TestFactories

  # Mark slow tests as pending unless explicitly requested
  config.filter_run_excluding :slow unless ENV['RUN_SLOW_TESTS'] == 'true'

  # Prevent environment variable leakage and working directory changes between examples
  config.around do |example|
    original_env = ENV.to_hash
    original_dir = Dir.pwd

    # Ensure tests run in CI mode to prevent interactive prompts
    # But allow VCR recording when explicitly requested via VCR_RECORD
    ENV["CI"] = "true" unless ENV.key?("CI") || ENV["VCR_RECORD"]

    # Set PROJECT_ROOT to prevent project root detection failures in tests
    # Point to the actual project root (handbook-meta) which contains the submodules
    unless ENV["PROJECT_ROOT"]
      ENV["PROJECT_ROOT"] = File.expand_path("../../..", __dir__)
    end

    example.run
  ensure
    # Restore environment and working directory
    ENV.replace(original_env)
    Dir.chdir(original_dir) if Dir.pwd != original_dir
  end

  # Suppress directory navigator warnings during tests to keep output clean
  config.before(:suite) do
    require_relative "../lib/coding_agent_tools/atoms/taskflow_management/directory_navigator"
    CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator.suppress_warnings = true
  rescue LoadError
    # Directory navigator not available, continue without suppression
  end

  config.after(:suite) do
    # Restore warning behavior after test suite completes

    CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator.suppress_warnings = false
  rescue NameError
    # Directory navigator not available, no action needed
  end
end
