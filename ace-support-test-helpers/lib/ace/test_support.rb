# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "tempfile"
require "tmpdir"
require "fileutils"
require "yaml"

require_relative "test_support/version"
require_relative "test_support/test_helper"  # Load helper module first
require_relative "test_support/cli_helpers"  # CLI testing utilities for ace-support-cli
require_relative "test_support/subprocess_runner"  # Subprocess isolation utilities
require_relative "test_support/base_test_case"  # Then base test case that uses it
require_relative "test_support/config_helpers"
require_relative "test_support/test_environment"
require_relative "test_support/performance_helpers"  # Performance testing utilities
require_relative "test_support/fixtures/bundle_mocks"  # Shared bundle mocks
require_relative "test_support/fixtures/git_mocks"  # Shared git mocks
require_relative "test_support/fixtures/http_mocks"  # Shared HTTP mocks for LLM testing
require_relative "test_support/fixtures/prompt_helpers"  # Shared prompt stubbing helpers
require_relative "test_support/fixtures/test_runner_mocks"  # Shared test runner mocks

# Configure Minitest reporters by default
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

module Ace
  module TestSupport
    # Main module for shared test utilities across ace-* gems
  end
end