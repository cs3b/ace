# frozen_string_literal: true

module Ace
  module Prompt
    module Atoms
      # Resolve model aliases to full model names
      class ModelAliasResolver
        DEFAULT_ALIASES = {
          "glite" => "google:gemini-2.0-flash-lite",
          "gflash" => "google:gemini-2.0-flash",
          "claude" => "anthropic:claude-3.5-sonnet",
          "haiku" => "anthropic:claude-3-haiku"
        }.freeze

        # Resolve model alias to full name
        # @param model [String] Model alias or full name
        # @param aliases [Hash] Custom aliases (default: DEFAULT_ALIASES)
        # @return [String] Full model name
        def self.resolve(model, aliases: DEFAULT_ALIASES)
          return model if model.nil? || model.empty?
          aliases.fetch(model, model)
        end

        # Check if model is an alias
        # @param model [String] Model name to check
        # @param aliases [Hash] Custom aliases (default: DEFAULT_ALIASES)
        # @return [Boolean] True if model is a known alias
        def self.alias?(model, aliases: DEFAULT_ALIASES)
          aliases.key?(model)
        end
      end
    end
  end
end
