# frozen_string_literal: true

require_relative 'validation_error'

module Ace
  module Lint
    module Models
      # Represents the validation result for a single file
      # @attr file_path [String] Path to the validated file
      # @attr success [Boolean] Whether validation passed
      # @attr errors [Array<ValidationError>] List of errors
      # @attr warnings [Array<ValidationError>] List of warnings
      # @attr formatted [Boolean] Whether file was formatted
      # @attr skipped [Boolean] Whether file was skipped (unsupported type)
      # @attr skip_reason [String] Reason for skipping (when skipped is true)
      # @attr runner [Symbol] Which linter was used (:standardrb, :rubocop, nil)
      LintResult = Struct.new(:file_path, :success, :errors, :warnings, :formatted, :skipped, :skip_reason, :runner, keyword_init: true) do
        def initialize(file_path:, success: true, errors: [], warnings: [], formatted: false, skipped: false, skip_reason: "Unsupported file type", runner: nil)
          super
        end

        def success?
          success
        end

        def failed?
          !success && !skipped
        end

        def formatted?
          formatted
        end

        def skipped?
          skipped
        end

        def has_errors?
          errors.any?
        end

        def has_warnings?
          warnings.any?
        end

        def error_count
          errors.size
        end

        def warning_count
          warnings.size
        end

        # Factory method for skipped results
        # @param file_path [String] Path to the skipped file
        # @param reason [String] Reason for skipping
        # @return [LintResult] Skipped result
        def self.skipped(file_path:, reason: "Unsupported file type")
          new(
            file_path: file_path,
            success: true,
            errors: [],
            warnings: [],
            formatted: false,
            skipped: true,
            skip_reason: reason
          )
        end
      end
    end
  end
end
