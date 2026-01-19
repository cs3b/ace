# frozen_string_literal: true

require "colorize"

module Ace
  module Lint
    module Organisms
      # Formats and displays validation results with colors
      class ResultReporter
        # Helper module for string operations
        module StringHelper
          # Pluralize a word based on count
          # @param word [String] Word to pluralize
          # @param count [Integer] Count for pluralization
          # @return [String] Singular or plural form
          def self.pluralize(word, count)
            (count == 1) ? word : "#{word}s"
          end
        end

        # Report results to stdout
        # @param results [Array<Models::LintResult>] Validation results
        # @param verbose [Boolean] Show detailed output (only used when no report)
        # @param report_dir [String, nil] Path to generated report directory
        # @param report_files [Hash, nil] Hash of generated files with counts
        def self.report(results, verbose: true, report_dir: nil, report_files: nil)
          # When report is generated, show only summary (details are in the report)
          # When no report (--no-report), show per-file details
          unless report_dir
            results.each do |result|
              report_single_result(result, verbose: verbose)
            end
            puts
          end

          report_summary(results, report_dir: report_dir, report_files: report_files)
        end

        # Get exit code based on results
        # @param results [Array<Models::LintResult>] Validation results
        # @return [Integer] Exit code (0 = success, 1 = failures)
        def self.exit_code(results)
          results.any?(&:failed?) ? 1 : 0
        end

        def self.report_single_result(result, verbose:)
          if result.skipped?
            report_skipped(result, verbose: verbose)
          elsif result.success
            report_success(result, verbose: verbose)
          else
            report_failure(result, verbose: verbose)
          end
        end

        def self.report_skipped(result, verbose:)
          if result.skip_reason && verbose
            puts "#{result.file_path}: #{"⊘".cyan} (skipped: #{result.skip_reason})"
          else
            puts "#{result.file_path}: #{"⊘".cyan} (skipped)"
          end
        end

        def self.report_success(result, verbose:)
          if result.formatted
            puts "#{result.file_path}: #{"✓".green} #{"(formatted)".yellow}"
          else
            puts "#{result.file_path}: #{"✓".green}"
          end

          return unless verbose && result.has_warnings?

          result.warnings.each do |warning|
            puts "  #{"⚠".yellow}  #{warning.to_s.yellow}"
          end
        end

        def self.report_failure(result, verbose:)
          puts "#{result.file_path}: #{"✗".red}"

          return unless verbose

          result.errors.each do |error|
            puts "  #{"✗".red}  #{error.to_s.red}"
          end

          result.warnings.each do |warning|
            puts "  #{"⚠".yellow}  #{warning.to_s.yellow}"
          end
        end

        def self.report_summary(results, report_dir: nil, report_files: nil)
          total = results.size
          fixed = results.count(&:formatted?)
          skipped = results.count(&:skipped?)
          failed = results.count(&:failed?)
          # Passed files: success but not formatted and not skipped
          passed = results.count { |r| r.success? && !r.formatted? && !r.skipped? }
          total_errors = results.sum(&:error_count)
          total_warnings = results.sum(&:warning_count)

          puts "=" * 60
          puts "Validated: #{total} #{StringHelper.pluralize("file", total)}"

          if failed.zero? && fixed.zero?
            puts "✓ All files passed".green
          else
            puts "✓ #{passed} passed".green if passed.positive?
            puts "✓ #{fixed} fixed".green if fixed.positive?
            puts "✗ #{failed} failed".red if failed.positive?
          end

          puts "⊘ #{skipped} skipped".cyan if skipped.positive?
          puts "  #{total_errors} #{StringHelper.pluralize("error", total_errors)}".red if total_errors.positive?
          puts "  #{total_warnings} #{StringHelper.pluralize("warning", total_warnings)}".yellow if total_warnings.positive?

          return unless report_dir && report_files

          puts
          puts "Reports: #{report_dir}/"
          report_files.each do |type, info|
            label = "#{type}.md".ljust(12)
            unit = (type == :pending) ? "issues" : "files"
            puts "  #{label} (#{info[:count]} #{unit})"
          end
        end
      end
    end
  end
end
