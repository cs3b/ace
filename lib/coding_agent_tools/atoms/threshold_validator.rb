# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Validates coverage threshold values and input parameters
    class ThresholdValidator
      class ValidationError < StandardError; end

      def initialize
        # No state needed - stateless atom
      end

      # Validates that a threshold is within acceptable range
      # @param threshold [Numeric] Coverage threshold percentage
      # @return [Float] Validated threshold as float
      # @raise [ValidationError] If threshold is invalid
      def validate_threshold(threshold)
        raise ValidationError, "Threshold cannot be nil" if threshold.nil?

        numeric_threshold = convert_to_numeric(threshold)
        validate_range(numeric_threshold)

        numeric_threshold.to_f
      end

      # Validates file path pattern for filtering
      # @param pattern [String] File pattern (glob-style)
      # @return [String] Validated pattern
      # @raise [ValidationError] If pattern is invalid
      def validate_file_pattern(pattern)
        return pattern if pattern.nil?

        raise ValidationError, "File pattern must be a string, got #{pattern.class}" unless pattern.is_a?(String)

        return pattern if pattern.empty?

        # Basic validation - no path traversal attempts
        raise ValidationError, "File pattern cannot contain path traversal sequences (../)" if pattern.include?("../")

        pattern.strip
      end

      # Validates format parameter
      # @param format [String] Output format
      # @return [String] Validated format
      # @raise [ValidationError] If format is invalid
      def validate_format(format)
        valid_formats = ["text", "json", "csv"]

        raise ValidationError, "Format must be a string, got #{format.class}" unless format.is_a?(String)

        normalized_format = format.strip.downcase

        unless valid_formats.include?(normalized_format)
          raise ValidationError, "Format must be one of: #{valid_formats.join(", ")}, got '#{format}'"
        end

        normalized_format
      end

      # Validates analysis mode parameter
      # @param mode [String] Analysis mode
      # @return [String] Validated mode
      # @raise [ValidationError] If mode is invalid
      def validate_analysis_mode(mode)
        return "both" if mode.nil?

        raise ValidationError, "Analysis mode must be a string, got #{mode.class}" unless mode.is_a?(String)

        return "both" if mode.empty?

        valid_modes = ["files", "methods", "both"]

        normalized_mode = mode.strip.downcase

        unless valid_modes.include?(normalized_mode)
          raise ValidationError, "Analysis mode must be one of: #{valid_modes.join(", ")}, got '#{mode}'"
        end

        normalized_mode
      end

      private

      def convert_to_numeric(threshold)
        case threshold
        when Numeric
          threshold
        when String
          Float(threshold)
        else
          raise ValidationError, "Threshold must be numeric, got #{threshold.class}"
        end
      rescue ArgumentError
        raise ValidationError, "Cannot convert '#{threshold}' to a number"
      end

      def validate_range(threshold)
        return if threshold.between?(0, 100)

        raise ValidationError, "Threshold must be between 0 and 100, got #{threshold}"
      end
    end
  end
end
