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
# Helper for safe ENV manipulation in specs
require_relative "support/env_helpers"
# ANSI color testing infrastructure
require_relative "support/ansi_color_testing_helper"
# Prevent interactive prompts in tests
require_relative "support/file_operation_confirmer_helper"

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
  # Prevent environment variable leakage between examples
  config.around do |example|
    original_env = ENV.to_hash
    # Ensure tests run in CI mode to prevent interactive prompts
    ENV['CI'] = 'true' unless ENV.key?('CI')
    example.run
  ensure
    ENV.replace(original_env)
  end
end
