# frozen_string_literal: true

require_relative "base_formatter"

module Ace
  module TestRunner
    module Formatters
      # Markdown formatter for generating individual failure report files
      # This formatter is used internally for creating detailed failure reports
      # It is not exposed as a user-selectable output format
      class MarkdownFormatter < BaseFormatter
        def initialize(options = {})
          super
          @configuration = options
        end

        # Generate markdown report for a single failure
        def generate_failure_report(failure, index)
          lines = []

          # Title with status
          status = failure.error? ? "ERROR" : "FAILURE"
          lines << "# Test #{status}: #{failure.test_name}"
          lines << ""
          lines << "**Status:** #{status}"
          lines << "**Location:** #{failure.location}" if failure.location
          lines << ""

          # Error Message
          lines << "## Error Message"
          lines << ""
          lines << failure.message if failure.message
          lines << ""

          # Stack Trace
          if failure.backtrace && !failure.backtrace.empty?
            lines << "## Stack Trace"
            lines << ""
            lines << "```"
            lines << failure.backtrace.take(15).join("\n")
            lines << "```"
            lines << ""
          end

          # Related stderr
          if failure.stderr_warnings && !failure.stderr_warnings.empty?
            lines << "## Related stderr"
            lines << ""
            lines << "```"
            lines << failure.stderr_warnings
            lines << "```"
            lines << ""
          end

          # Code Context
          if failure.code_context && failure.code_context[:lines]
            lines << "## Code Context"
            lines << ""
            lines << "```ruby"
            failure.code_context[:lines].each do |line_num, line_data|
              marker = line_data[:highlighted] ? "← ERROR HERE" : ""
              lines << format("%3d:  %s  %s", line_num, line_data[:content], marker)
            end
            lines << "```"
            lines << ""
          end

          # Fix Suggestion
          if failure.fix_suggestion
            lines << "## Fix Suggestion"
            lines << ""
            lines << failure.fix_suggestion
            lines << ""
          end

          lines.join("\n")
        end

        # Not used for console output
        def format_stdout(result)
          ""
        end

        # Not used for report generation
        def format_report(report)
          {}
        end
      end
    end
  end
end