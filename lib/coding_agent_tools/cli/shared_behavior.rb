# frozen_string_literal: true

module CodingAgentTools
  module Cli
    # SharedBehavior module provides common functionality for CLI commands
    # This module extracts shared patterns from CLI command classes to reduce duplication
    module SharedBehavior
      # Filter models based on search term
      # @param models [Array] Array of model objects
      # @param filter_term [String, nil] Filter term for fuzzy search
      # @return [Array] Filtered models
      def filter_models(models, filter_term)
        return models unless filter_term

        filter_term = filter_term.downcase
        models.select do |model|
          model.id.downcase.include?(filter_term) ||
            model.name.downcase.include?(filter_term) ||
            model.description.downcase.include?(filter_term)
        end
      end

      # Output models in the specified format
      # @param models [Array] Array of model objects
      # @param options [Hash] Command options
      def output_models(models, options)
        case options[:format]
        when "json"
          output_json_models(models)
        else
          output_text_models(models)
        end
      end

      # Handle command errors with optional debug output
      # @param error [Exception] The error that occurred
      # @param debug_enabled [Boolean] Whether to show debug information
      def handle_error(error, debug_enabled)
        if debug_enabled
          error_output("Error: #{error.class.name}: #{error.message}")
          error_output("\nBacktrace:")
          error.backtrace.each { |line| error_output("  #{line}") }
        else
          error_output("Error: #{error.message}")
          error_output("Use --debug flag for more information")
        end
        exit 1
      end

      # Output error message to stderr
      # @param message [String] Error message
      def error_output(message)
        warn message
      end

      private

      # Output models as formatted text
      # This method should be implemented by including classes
      # as the format varies between command types
      def output_text_models(models)
        raise NotImplementedError, "Subclasses must implement output_text_models"
      end

      # Output models as JSON
      # This method should be implemented by including classes
      # as the JSON structure varies between command types
      def output_json_models(models)
        raise NotImplementedError, "Subclasses must implement output_json_models"
      end
    end
  end
end
