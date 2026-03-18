# frozen_string_literal: true

require_relative "../atoms/standardrb_runner"
require_relative "../atoms/rubocop_runner"
require_relative "../models/lint_result"
require_relative "../models/validation_error"
require_relative "validator_chain"

module Ace
  module Lint
    module Molecules
      # Lints Ruby files using StandardRB (preferred) with RuboCop fallback
      # Supports multi-validator mode via ValidatorChain
      class RubyLinter
        # Lint a Ruby file
        # @param file_path [String] Path to the Ruby file
        # @param options [Hash] Linting options
        # @option options [Boolean] :fix Apply autofix
        # @option options [Array<Symbol>] :validators Specific validators to use
        # @option options [Array<Symbol>] :fallback_validators Fallback validators
        # @return [Models::LintResult] Lint result
        def self.lint(file_path, options: {})
          fix = options[:fix] || false
          validators = options[:validators]
          fallback_validators = options[:fallback_validators]

          # Read file content before running validators to detect actual changes
          before_content = fix ? File.read(file_path) : nil

          result, runner = run_validators([file_path], fix: fix, validators: validators,
            fallback_validators: fallback_validators)

          # Determine success by error count, not runner exit status
          # (runner exits non-zero for convention warnings too)
          file_errors = result[:errors] || []
          file_warnings = result[:warnings] || []

          # Read file once after validation to detect formatting changes
          after_content = fix ? File.read(file_path) : nil

          Models::LintResult.new(
            file_path: file_path,
            success: file_errors.empty?,
            errors: convert_to_validation_errors(file_errors),
            warnings: convert_to_validation_errors(file_warnings),
            formatted: fix && before_content != after_content,
            runner: runner
          )
        rescue => e
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "Ruby linting failed: #{e.message}")],
            warnings: [],
            formatted: false,
            runner: nil
          )
        end

        # Lint multiple Ruby files in a single subprocess
        # Supports multiple validators via ValidatorChain
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param options [Hash] Linting options
        # @option options [Boolean] :fix Apply autofix
        # @option options [Array<Symbol>] :validators Specific validators to use
        # @option options [Array<Symbol>] :fallback_validators Fallback validators
        # @option options [Boolean] :quiet Suppress chain warnings (default: false)
        # @return [Array<Models::LintResult>] Lint results for each file
        def self.lint_batch(file_paths, options: {})
          return [] if file_paths.empty?

          fix = options[:fix] || false
          quiet = options[:quiet] || false
          validators = options[:validators]
          fallback_validators = options[:fallback_validators]

          # Read file contents before running validators to detect actual changes
          before_contents = fix ? file_paths.to_h { |fp| [fp, File.read(fp)] } : {}

          result, runner = run_validators(file_paths, fix: fix, validators: validators,
            fallback_validators: fallback_validators)

          # Surface chain-level warnings (e.g., unavailable validators) unless quiet
          unless quiet
            chain_warnings = result[:chain_warnings] || []
            chain_warnings.each do |warning|
              warn "[ace-lint] #{warning}"
            end
          end

          # Group offenses by file
          offenses_by_file = Hash.new { |h, k| h[k] = {errors: [], warnings: []} }

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
                formatted: false,
                runner: runner
              )
            end
          end

          # Read files once after validation to detect formatting changes
          after_contents = fix ? file_paths.to_h { |fp| [fp, File.read(fp)] } : {}

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
              formatted: fix && before_contents[file_path] != after_contents[file_path],
              runner: runner
            )
          end
        rescue => e
          # If batch fails, return individual error results for each file
          # Include error context for debugging
          warn "Ruby batch linting failed: #{e.message}" if $VERBOSE
          file_paths.map do |file_path|
            Models::LintResult.new(
              file_path: file_path,
              success: false,
              errors: [Models::ValidationError.new(message: "Batch linting failed: #{e.message}")],
              warnings: [],
              formatted: false,
              runner: nil
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

        # Run linting with validators via ValidatorChain
        # @param file_paths [Array<String>] Paths to Ruby files
        # @param fix [Boolean] Apply autofix
        # @param validators [Array<Symbol>, nil] Specific validators to use
        # @param fallback_validators [Array<Symbol>, nil] Fallback validators
        # @return [Array<Hash, Symbol|Array>] Result and runner(s) used
        def self.run_validators(file_paths, fix:, validators: nil, fallback_validators: nil)
          validators = [:standardrb] if validators.nil? || validators.empty?
          chain = ValidatorChain.new(validators, fallback_validators: fallback_validators || [])
          result = chain.run(file_paths, fix: fix)
          runners = result[:runners] || []
          runner = (runners.size == 1) ? runners.first : runners
          [result, runner]
        end
        private_class_method :run_validators

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
