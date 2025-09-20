# frozen_string_literal: true

require "ace/core"
require "ace/test_support"

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

# Atoms - Basic utilities
require_relative "test_runner/atoms/test_detector"
require_relative "test_runner/atoms/command_builder"
require_relative "test_runner/atoms/result_parser"
require_relative "test_runner/atoms/timestamp_generator"

# Molecules - Composed operations
require_relative "test_runner/molecules/test_executor"
require_relative "test_runner/molecules/failure_analyzer"
require_relative "test_runner/molecules/deprecation_fixer"
require_relative "test_runner/molecules/report_storage"

# Formatters
require_relative "test_runner/formatters/base_formatter"
require_relative "test_runner/formatters/ai_formatter"
require_relative "test_runner/formatters/compact_formatter"
require_relative "test_runner/formatters/json_formatter"
require_relative "test_runner/formatters/markdown_formatter"

# Organisms - Business logic
require_relative "test_runner/organisms/test_orchestrator"
require_relative "test_runner/organisms/report_generator"
require_relative "test_runner/organisms/agent_reporter"

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