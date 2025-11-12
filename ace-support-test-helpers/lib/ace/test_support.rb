# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "tempfile"
require "tmpdir"
require "fileutils"
require "yaml"

require_relative "test_support/version"
require_relative "test_support/test_helper"  # Load helper module first
require_relative "test_support/subprocess_runner"  # Subprocess isolation utilities
require_relative "test_support/base_test_case"  # Then base test case that uses it
require_relative "test_support/config_helpers"
require_relative "test_support/test_environment"
require_relative "test_support/performance_helpers"  # Performance testing utilities
require_relative "test_support/fixtures/context_mocks"  # Shared context mocks
require_relative "test_support/fixtures/git_mocks"  # Shared git mocks

# Configure Minitest reporters by default
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

module Ace
  module TestSupport
    # Main module for shared test utilities across ace-* gems
  end
end