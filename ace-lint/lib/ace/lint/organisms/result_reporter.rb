# frozen_string_literal: true

require 'colorize'

module Ace
  module Lint
    module Organisms
      # Formats and displays validation results with colors
      class ResultReporter
        # Report results to stdout
        # @param results [Array<Models::LintResult>] Validation results
        # @param verbose [Boolean] Show detailed output
        def self.report(results, verbose: true)
          results.each do |result|
            report_single_result(result, verbose: verbose)
          end

          puts
          report_summary(results)
        end

        # Get exit code based on results
        # @param results [Array<Models::LintResult>] Validation results
        # @return [Integer] Exit code (0 = success, 1 = failures)
        def self.exit_code(results)
          results.any?(&:failed?) ? 1 : 0
        end

        def self.report_single_result(result, verbose:)
          if result.success
            report_success(result, verbose: verbose)
          else
            report_failure(result, verbose: verbose)
          end
        end

        def self.report_success(result, verbose:)
          if result.formatted
            puts "#{result.file_path}: #{'✓'.green} #{'(formatted)'.yellow}"
          else
            puts "#{result.file_path}: #{'✓'.green}"
          end

          return unless verbose && result.has_warnings?

          result.warnings.each do |warning|
            puts "  #{'⚠'.yellow}  #{warning.to_s.yellow}"
          end
        end

        def self.report_failure(result, verbose:)
          puts "#{result.file_path}: #{'✗'.red}"

          return unless verbose

          result.errors.each do |error|
            puts "  #{'✗'.red}  #{error.to_s.red}"
          end

          result.warnings.each do |warning|
            puts "  #{'⚠'.yellow}  #{warning.to_s.yellow}"
          end
        end

        def self.report_summary(results)
          total = results.size
          passed = results.count(&:success)
          failed = results.count(&:failed?)
          total_errors = results.sum(&:error_count)
          total_warnings = results.sum(&:warning_count)

          puts '=' * 60
          puts "Validated: #{total} #{'file'.pluralize(total)}"

          if failed.zero?
            puts '✓ All files passed'.green
          else
            puts "✓ #{passed} passed".green if passed.positive?
            puts "✗ #{failed} failed".red if failed.positive?
          end

          puts "  #{total_errors} #{'error'.pluralize(total_errors)}".red if total_errors.positive?
          puts "  #{total_warnings} #{'warning'.pluralize(total_warnings)}".yellow if total_warnings.positive?
        end
      end
    end
  end
end

# Helper for string pluralization
class String
  def pluralize(count)
    count == 1 ? self : "#{self}s"
  end
end
