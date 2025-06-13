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
    example.run
  ensure
    ENV.replace(original_env)
  end
end
