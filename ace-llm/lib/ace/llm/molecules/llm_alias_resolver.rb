# frozen_string_literal: true

require "yaml"
require "ace/core"

module Ace
  module LLM
    module Molecules
      # LlmAliasResolver resolves LLM aliases to their actual model names
      # It supports both global aliases and provider-specific aliases with proper precedence
      class LlmAliasResolver
        # Config file paths (supports both .ace and .coding-agent for backward compatibility)
        ACE_CONFIG_FILENAME = "llm/aliases.yml"
        LEGACY_CONFIG_PATH = ".coding-agent/llm-aliases.yml"
        USER_CONFIG_SUBDIR = ".config/ace-llm"
        USER_CONFIG_FILE = "aliases.yml"

        # Empty default structure when no config files exist
        EMPTY_CONFIG = {
          "global" => {},
          "providers" => {}
        }.freeze

        attr_reader :aliases_config

        # Initialize alias resolver
        def initialize
          @aliases_config = load_aliases_config
        end

        # Resolve an alias or model name to its actual provider:model format
        # @param input [String] The input model name or alias
        # @return [String] The resolved provider:model format
        def resolve(input)
          input = input.to_s.strip

          # If already in provider:model format, check provider-specific aliases first
          if input.include?(":")
            provider, model_part = input.split(":", 2)
            resolved = resolve_provider_alias(provider, model_part)
            return "#{provider}:#{resolved}" if resolved

            # Return as-is if no alias found (assume direct model name)
            return input
          end

          # Check global aliases first
          global_resolved = resolve_global_alias(input)
          return global_resolved if global_resolved

          # If no global alias found, return as-is (assume direct model name)
          input
        end

        # Check if a given input is an alias
        # @param input [String] The input to check
        # @return [Boolean] True if the input is a recognized alias
        def alias?(input)
          input = input.to_s.strip

          if input.include?(":")
            provider, model_part = input.split(":", 2)
            return resolve_provider_alias(provider, model_part) != nil
          end

          resolve_global_alias(input) != nil
        end

        # Get all available aliases
        # @return [Hash] Hash containing global and provider aliases
        def available_aliases
          {
            global: @aliases_config.dig("global") || {},
            providers: @aliases_config.dig("providers") || {}
          }
        end

        # Get aliases for a specific provider
        # @param provider [String] Provider name
        # @return [Hash] Provider-specific aliases
        def provider_aliases(provider)
          @aliases_config.dig("providers", provider) || {}
        end

        private

        # Load aliases configuration from project, user, or default config
        # @return [Hash] Loaded aliases configuration
        def load_aliases_config
          # Try ace-core config cascade first
          config = load_from_ace_config
          return config if config

          # Check legacy project config (.coding-agent/llm-aliases.yml)
          if defined?(Ace::Core::Molecules::ProjectRootFinder)
            begin
              project_root = Ace::Core::Molecules::ProjectRootFinder.find
              legacy_config_path = File.join(project_root, LEGACY_CONFIG_PATH)
              if File.exist?(legacy_config_path)
                return load_yaml_config(legacy_config_path)
              end
            rescue => e
              # Continue to other options if project root not found
            end
          end

          # Check user config (~/.config/ace-llm/aliases.yml)
          user_config_path = user_aliases_config_path
          if File.exist?(user_config_path)
            return load_yaml_config(user_config_path)
          end

          # Return empty config if no files found
          EMPTY_CONFIG.dup
        end

        # Load configuration using ace-core's config cascade
        # @return [Hash, nil] Loaded configuration or nil if not found
        def load_from_ace_config
          return nil unless defined?(Ace::Core::Organisms::ConfigResolver)

          begin
            resolver = Ace::Core::Organisms::ConfigResolver.new
            config_result = resolver.resolve(ACE_CONFIG_FILENAME)

            if config_result && config_result.found?
              return config_result.merged_config
            end
          rescue => e
            # Fall back to other methods if ace-core not available
          end

          nil
        end

        # Get path to user aliases config file
        # @return [String] Path to user config file
        def user_aliases_config_path
          home_dir = ENV["HOME"] || Dir.home
          config_dir = File.join(home_dir, USER_CONFIG_SUBDIR)
          File.join(config_dir, USER_CONFIG_FILE)
        end

        # Load YAML configuration from file with error handling
        # @param config_path [String] Path to config file
        # @return [Hash] Loaded configuration
        def load_yaml_config(config_path)
          content = File.read(config_path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue => e
          warn "Warning: Failed to load aliases config from #{config_path}: #{e.message}"
          { "global" => {}, "providers" => {} }
        end

        # Resolve global alias
        # @param alias_name [String] The alias to resolve
        # @return [String, nil] Resolved provider:model or nil if not found
        def resolve_global_alias(alias_name)
          global_aliases = @aliases_config.dig("global")
          return nil unless global_aliases

          # Support both string and symbol keys
          global_aliases[alias_name.to_s] || global_aliases[alias_name.to_sym]
        end

        # Resolve provider-specific alias
        # @param provider [String] The provider name
        # @param alias_name [String] The alias to resolve
        # @return [String, nil] Resolved model name or nil if not found
        def resolve_provider_alias(provider, alias_name)
          provider_aliases = @aliases_config.dig("providers", provider)
          return nil unless provider_aliases

          # Support both string and symbol keys
          provider_aliases[alias_name.to_s] || provider_aliases[alias_name.to_sym]
        end
      end
    end
  end
end