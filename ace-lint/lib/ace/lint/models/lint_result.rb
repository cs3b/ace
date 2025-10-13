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
      LintResult = Struct.new(:file_path, :success, :errors, :warnings, :formatted) do
        def initialize(file_path:, success: true, errors: [], warnings: [], formatted: false)
          super(file_path, success, errors, warnings, formatted)
        end

        def failed?
          !success
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
      end
    end
  end
end
