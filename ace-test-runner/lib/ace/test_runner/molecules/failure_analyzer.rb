# frozen_string_literal: true

module Ace
  module TestRunner
    module Molecules
      # Analyzes test failures and provides insights
      class FailureAnalyzer
        COMMON_PATTERNS = {
          assertion: {
            pattern: /Expected: (.+)\n\s+Actual: (.+)/m,
            suggestion: "Check the assertion values. Expected and actual don't match."
          },
          nil_error: {
            pattern: /undefined method .+ for nil:NilClass/,
            suggestion: "Object is nil. Add nil check or ensure object is initialized."
          },
          missing_constant: {
            pattern: /uninitialized constant (\S+)/,
            suggestion: "Class or module not found. Check requires/imports or class name spelling."
          },
          argument_error: {
            pattern: /wrong number of arguments \(given (\d+), expected (\d+)\)/,
            suggestion: "Method called with wrong number of arguments. Check method signature."
          },
          file_not_found: {
            pattern: /No such file or directory/,
            suggestion: "File doesn't exist. Check file path or create the file."
          },
          syntax_error: {
            pattern: /syntax error/,
            suggestion: "Ruby syntax error. Check for missing brackets, quotes, or keywords."
          },
          timeout: {
            pattern: /execution expired|timeout/i,
            suggestion: "Operation timed out. Consider increasing timeout or optimizing slow code."
          }
        }.freeze

        def analyze_failure(failure_data)
          return failure_data unless failure_data.is_a?(Hash)

          message = failure_data[:message] || failure_data[:full_content] || ""

          # Try to extract test class and method
          if failure_data[:test_name] && failure_data[:test_name].include?("#")
            parts = failure_data[:test_name].split("#")
            failure_data[:test_class] = parts[0]
            failure_data[:test_name] = parts[1]
          end

          # Analyze the error message for common patterns
          suggestion = find_suggestion(message)
          failure_data[:fix_suggestion] = suggestion if suggestion

          # Extract file and line from location if available
          if failure_data[:location] && failure_data[:location].is_a?(Hash)
            failure_data[:file_path] = failure_data[:location][:file]
            failure_data[:line_number] = failure_data[:location][:line]
          end

          Models::TestFailure.new(failure_data)
        end

        def analyze_all(failures)
          return [] unless failures.is_a?(Array)

          failures.map { |failure| analyze_failure(failure) }
        end

        def group_by_type(failures)
          failures.group_by(&:type)
        end

        def group_by_file(failures)
          failures.group_by(&:file_path).compact
        end

        def find_common_issues(failures)
          issues = {}

          # Count occurrences of each type of error
          failures.each do |failure|
            COMMON_PATTERNS.each do |issue_type, config|
              if failure.message&.match?(config[:pattern])
                issues[issue_type] ||= { count: 0, failures: [], suggestion: config[:suggestion] }
                issues[issue_type][:count] += 1
                issues[issue_type][:failures] << failure
              end
            end
          end

          issues.sort_by { |_, v| -v[:count] }.to_h
        end

        def generate_fix_script(failures)
          fixes = []

          failures.each do |failure|
            if failure.message&.match?(/DEPRECATION WARNING/)
              fixes << generate_deprecation_fix(failure)
            elsif failure.message&.match?(/undefined method/)
              fixes << generate_method_fix(failure)
            end
          end

          fixes.compact
        end

        private

        def find_suggestion(message)
          COMMON_PATTERNS.each do |_, config|
            return config[:suggestion] if message.match?(config[:pattern])
          end

          # Generic suggestions based on keywords
          case message
          when /permission denied/i
            "Check file/directory permissions"
          when /connection refused/i
            "Service not running or wrong connection settings"
          when /invalid/i
            "Check input validation and data format"
          when /not found/i
            "Resource doesn't exist. Check paths and names"
          else
            nil
          end
        end

        def generate_deprecation_fix(failure)
          {
            file: failure.file_path,
            line: failure.line_number,
            type: :deprecation,
            fix: extract_deprecation_fix(failure.message)
          }
        end

        def generate_method_fix(failure)
          if failure.message =~ /undefined method `(.+)' for/
            method = $1
            {
              file: failure.file_path,
              line: failure.line_number,
              type: :missing_method,
              fix: "Define method '#{method}' or check spelling"
            }
          end
        end

        def extract_deprecation_fix(message)
          # Look for "use X instead" patterns
          if message =~ /use (.+) instead/i
            "Replace with: #{$1}"
          else
            "Update deprecated code"
          end
        end
      end
    end
  end
end