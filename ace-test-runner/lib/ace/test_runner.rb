# frozen_string_literal: true

# require "ace/core"  # TODO: Enable when ace-core is available
# Don't require ace/test_support here - it loads minitest/autorun which causes double runs
# Test files will require it themselves

# Only require minitest when actually running tests
# require "minitest" is done by test files or CommandBuilder
# require "minitest/reporters" is done when needed
require "open3"
require "json"
require "yaml"
require "fileutils"
require "time"

require_relative "test_runner/version"

# Models - Pure data structures
require_relative "test_runner/models/test_result"
require_relative "test_runner/models/test_failure"
require_relative "test_runner/models/test_configuration"
require_relative "test_runner/models/test_report"

# Atoms - Basic utilities (always needed)
require_relative "test_runner/atoms/test_detector"
require_relative "test_runner/atoms/command_builder"
require_relative "test_runner/atoms/result_parser"
require_relative "test_runner/atoms/timestamp_generator"
require_relative "test_runner/atoms/lazy_loader"

# Molecules - Core operations (always needed for basic test running)
require_relative "test_runner/molecules/test_executor"
require_relative "test_runner/molecules/failure_analyzer"
require_relative "test_runner/molecules/report_storage"
require_relative "test_runner/molecules/config_loader"
require_relative "test_runner/molecules/pattern_resolver"
# Other molecules loaded lazily (deprecation_fixer, rake_integration)

# Formatters - Load only base formatter, others loaded on demand
require_relative "test_runner/formatters/base_formatter"
# Other formatters loaded lazily via LazyLoader

# Organisms - Core orchestrators always needed for test execution
require_relative "test_runner/organisms/test_orchestrator"
require_relative "test_runner/organisms/report_generator"
# Agent reporter loaded lazily when needed

module Ace
  module TestRunner
    class Error < StandardError; end

    class << self
      def run(options = {})
        orchestrator = Organisms::TestOrchestrator.new(options)
        orchestrator.run
      end
    end
  end
end