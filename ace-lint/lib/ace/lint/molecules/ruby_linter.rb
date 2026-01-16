# frozen_string_literal: true

require_relative '../atoms/standardrb_runner'
require_relative '../models/lint_result'
require_relative '../models/validation_error'

module Ace
  module Lint
    module Molecules
      # Lints Ruby files using StandardRB
      class RubyLinter
        # Lint a Ruby file
        # @param file_path [String] Path to the Ruby file
        # @param options [Hash] Linting options
        # @option options [Boolean] :fix Apply autofix
        # @return [Models::LintResult] Lint result
        def self.lint(file_path, options: {})
          fix = options[:fix] || false

          result = Atoms::StandardrbRunner.run(file_path, fix: fix)

          if result[:success]
            Models::LintResult.new(
              file_path: file_path,
              success: true,
              errors: [],
              warnings: convert_to_validation_errors(result[:warnings]),
              formatted: fix
            )
          else
            Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: convert_to_validation_errors(result[:errors]),
              warnings: convert_to_validation_errors(result[:warnings]),
              formatted: fix
            )
          end
        rescue StandardError => e
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "Ruby linting failed: #{e.message}")],
            warnings: [],
            formatted: false
          )
        end

        # Lint multiple Ruby files in a single StandardRB subprocess
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param options [Hash] Linting options
        # @option options [Boolean] :fix Apply autofix
        # @return [Array<Models::LintResult>] Lint results for each file
        def self.lint_batch(file_paths, options: {})
          return [] if file_paths.empty?

          fix = options[:fix] || false
          result = Atoms::StandardrbRunner.run(file_paths, fix: fix)

          # Group offenses by file
          offenses_by_file = Hash.new { |h, k| h[k] = { errors: [], warnings: [] } }

          result[:errors].each do |offense|
            offenses_by_file[offense[:file] || :_general_][:errors] << offense
          end

          result[:warnings].each do |offense|
            offenses_by_file[offense[:file] || :_general_][:warnings] << offense
          end

          # Check for runner-level failure (errors without file context)
          # If all errors are general (no :file key), the runner itself failed
          general_errors = offenses_by_file[:_general_]&.dig(:errors) || []
          file_specific_errors_exist = offenses_by_file.keys.any? { |k| k != :_general_ }

          if !result[:success] && general_errors.any? && !file_specific_errors_exist
            # Runner failed with no file-specific offenses - propagate to all files
            error_msg = general_errors.first&.dig(:message) || "StandardRB execution failed"
            return file_paths.map do |file_path|
              Models::LintResult.new(
                file_path: file_path,
                success: false,
                errors: [Models::ValidationError.new(message: error_msg)],
                warnings: [],
                formatted: false
              )
            end
          end

          # Create a LintResult for each file
          file_paths.map do |file_path|
            offenses = offenses_by_file[file_path]
            general = offenses_by_file[:_general_]

            # Include general errors (without file context) for each file
            file_errors = (offenses ? offenses[:errors] : []) + (general ? general[:errors] : [])
            file_warnings = (offenses ? offenses[:warnings] : []) + (general ? general[:warnings] : [])

            Models::LintResult.new(
              file_path: file_path,
              success: file_errors.empty?,
              errors: convert_to_validation_errors(file_errors),
              warnings: convert_to_validation_errors(file_warnings),
              formatted: fix
            )
          end
        rescue StandardError => e
          # If batch fails, return individual error results for each file
          # Include error context for debugging
          warn "Ruby batch linting failed: #{e.message}" if $VERBOSE
          file_paths.map do |file_path|
            Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: [Models::ValidationError.new(message: "Batch linting failed: #{e.message}")],
              warnings: [],
              formatted: false
            )
          end
        end

        # Convert offense hash to ValidationError
        # @param offenses [Array<Hash>] Offense data
        # @return [Array<Models::ValidationError>] Validation errors
        def self.convert_to_validation_errors(offenses)
          return [] if offenses.nil? || offenses.empty?

          offenses.map do |offense|
            message = build_offense_message(offense)
            Models::ValidationError.new(message: message)
          end
        end

        # Build formatted offense message
        # @param offense [Hash] Offense data
        # @return [String] Formatted message
        def self.build_offense_message(offense)
          file = offense[:file]
          line = offense[:line]
          column = offense[:column]
          message = offense[:message]

          if file && line && line > 0
            "#{file}:#{line}:#{column}: #{message}"
          else
            message
          end
        end
      end
    end
  end
end
