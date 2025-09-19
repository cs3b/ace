# frozen_string_literal: true

module CodingAgentTools
  module Constants
    # CLI constants for command-line interface functionality
    module CliConstants
      # Output format constants
      FORMAT_TEXT = "text"
      FORMAT_JSON = "json"
      VALID_FORMATS = [FORMAT_TEXT, FORMAT_JSON].freeze

      # Role constants for AI interactions
      ROLE_USER = "user"
      ROLE_ASSISTANT = "assistant"
      ROLE_SYSTEM = "system"

      # Common CLI messages
      NO_MODELS_FOUND_MESSAGE = "No models found matching the filter criteria."
      DEBUG_FLAG_MESSAGE = "Use --debug flag for more information"

      # Formatting constants
      SEPARATOR_LINE = "=" * 50
      ERROR_PREFIX = "Error:"

      # Model-related constants
      MODELS_PREFIX = "models/"
      GENERATE_CONTENT_METHOD = "generateContent"

      # Common CLI options
      FILTER_OPTION_ALIASES = ["f"].freeze
      DEBUG_OPTION_ALIASES = ["d"].freeze

      # Model name formatting
      MODEL_NAME_MAPPINGS = {
        "gemini" => "Gemini",
        "flash" => "Flash",
        "pro" => "Pro",
        "lite" => "Lite",
        "preview" => "Preview"
      }.freeze
    end
  end
end
