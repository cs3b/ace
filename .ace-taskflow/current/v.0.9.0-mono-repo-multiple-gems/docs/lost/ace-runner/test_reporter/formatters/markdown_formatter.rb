# frozen_string_literal: true

module AceTools
  module TestReporter
    module Formatters
      class MarkdownFormatter
        def generate_failure_filename(result, index)
          # Create a safe filename from the test name
          test_name = result.name.gsub(/\W+/, '_').downcase
          test_name = test_name[0...50] if test_name.length > 50
          format('%03d-%s.md', index, test_name)
        end

        def format_failure_report(result)
          lines = []

          # Header
          lines << "# Test Failure Report"
          lines << ""
          lines << "## Test Information"
          lines << "- **Test Name**: `#{result.name}`"
          lines << "- **Test Class**: `#{result.class_name}`"

          # Get location from failure if available
          if result.failure && result.failure.respond_to?(:location) && result.failure.location
            location_parts = result.failure.location.split(':')
            lines << "- **File**: `#{location_parts[0]}`"
            lines << "- **Line**: #{location_parts[1]}"
          else
            lines << "- **File**: Unknown"
            lines << "- **Line**: Unknown"
          end

          lines << "- **Execution Time**: #{format('%.4f', result.time)} seconds"
          lines << ""

          # Error details
          lines << "## Error Details"
          if result.failure
            lines << "- **Error Type**: `#{result.failure.class.name}`"
            lines << ""
            lines << "### Error Message"
            lines << "```"
            lines << clean_message(result.failure.message)
            lines << "```"
            lines << ""

            # Assertion details if available
            if result.failure.message.include?('Expected')
              lines << "### Assertion Details"
              lines.concat(extract_assertion_details(result.failure.message))
              lines << ""
            end

            # Stack trace
            lines << "### Stack Trace"
            lines << "```"
            lines.concat(format_backtrace(result.failure.backtrace))
            lines << "```"
            lines << ""
          end

          # Code context if available
          begin
            if result.failure && result.failure.respond_to?(:location) && result.failure.location
              location_parts = result.failure.location.split(':')
              file_path = location_parts[0]
              line_number = location_parts[1]&.to_i

              if file_path && file_path.is_a?(String) && !file_path.empty? &&
                 line_number && line_number > 0 && File.exist?(file_path)
                lines << "## Code Context"
                lines.concat(extract_code_context([file_path, line_number]))
                lines << ""
              end
            end
          rescue => e
            # Silently ignore errors in code context extraction
          end

          # Additional debugging info
          lines << "## Debug Information"
          lines << "- **Test Result**: #{result.result_code}"
          lines << "- **Assertions**: #{result.assertions}"
          lines << "- **Test Suite**: #{detect_test_suite(result)}"

          lines.join("\n")
        end

        private

        def clean_message(message)
          # Remove excessive whitespace and format for readability
          message.to_s
                 .gsub(/\n\s*\n/, "\n\n")
                 .strip
        end

        def extract_assertion_details(message)
          lines = []

          # Try to extract expected vs actual values
          if message =~ /Expected:\s*(.+?)\s*Actual:\s*(.+)/m
            expected = Regexp.last_match(1).strip
            actual = Regexp.last_match(2).strip

            lines << "#### Expected"
            lines << "```"
            lines << expected
            lines << "```"
            lines << ""
            lines << "#### Actual"
            lines << "```"
            lines << actual
            lines << "```"
          else
            lines << "```"
            lines << message
            lines << "```"
          end

          lines
        end

        def format_backtrace(backtrace)
          return ['No backtrace available'] unless backtrace

          # Get project root safely
          project_root = begin
            require_relative '../../atoms/project_root_detector'
            AceTools::Atoms::ProjectRootDetector.find_project_root
          rescue StandardError
            # Fallback to a stored value or empty string
            ENV['PROJECT_ROOT'] || ''
          end

          # Filter and format the backtrace
          backtrace.reject { |line| line.include?('/minitest/') || line.include?('/ruby/') }
                   .first(15)
                   .map { |line| project_root.empty? ? line : line.sub(/^#{Regexp.escape(project_root)}\//, '') }
        end

        def extract_code_context(location)
          file, line_num = location
          lines = []

          begin
            file_lines = File.readlines(file)
            start_line = [line_num - 5, 1].max
            end_line = [line_num + 5, file_lines.size].min

            lines << "```ruby"
            (start_line..end_line).each do |i|
              line_content = file_lines[i - 1]
              marker = i == line_num ? '> ' : '  '
              lines << format('%s%4d: %s', marker, i, line_content.rstrip)
            end
            lines << "```"
          rescue StandardError => e
            lines << "Could not extract code context: #{e.message}"
          end

          lines
        end

        def detect_test_suite(result)
          if result.source_location&.first
            path = result.source_location.first
            case path
            when /\/atoms\//
              'ATOMS'
            when /\/molecules\//
              'MOLECULES'
            when /\/organisms\//
              'ORGANISMS'
            when /\/ecosystems\//
              'ECOSYSTEMS'
            when /\/integration\//
              'INTEGRATION'
            when /\/unit\//
              'UNIT'
            else
              'GENERAL'
            end
          else
            'UNKNOWN'
          end
        end
      end
    end
  end
end