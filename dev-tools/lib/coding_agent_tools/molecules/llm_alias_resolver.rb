# frozen_string_literal: true

require "yaml"
require "fileutils"
require_relative "../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    # LlmAliasResolver is a molecule that resolves LLM aliases to their actual model names
    # It supports both global aliases and provider-specific aliases with proper precedence
    class LlmAliasResolver
      # Config file locations
      PROJECT_CONFIG_PATH = ".coding-agent/llm-aliases.yml"
      USER_CONFIG_SUBDIR = ".config/coding-agent-tools"
      USER_CONFIG_FILE = "llm-aliases.yml"
      
      # Minimal hardcoded defaults as emergency fallback
      DEFAULT_ALIASES = {
        "global" => {
          "gflash" => "google:gemini-2.5-flash",
          "gpro" => "google:gemini-2.5-pro",
          "gfast" => "google:gemini-2.5-flash-lite",
          "opus" => "cc:opus",
          "sonnet" => "cc:sonnet",
          "haiku" => "cc:haiku",
          "gpt5" => "openai:gpt-5",
          "gpt5mini" => "openai:gpt-5-mini",
          "gpt5nano" => "openai:gpt-5-nano"
        },
        "providers" => {
          "cc" => {
            "opus" => "opus",
            "sonnet" => "sonnet",
            "haiku" => "haiku"
          }
        }
      }.freeze

      attr_reader :aliases_config

      # Initialize alias resolver
      def initialize
        @aliases_config = load_aliases_config
      end

      # Resolve an alias or model name to its actual provider:model format
      # @param input [String] The input model name or alias (e.g. "opus", "cc:haiku", "google:gemini-1.5-pro")
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

      # Check if a given input is an alias (either global or provider-specific)
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

      private

      # Load aliases configuration from project, user, or default config
      # @return [Hash] Loaded aliases configuration
      def load_aliases_config
        # Check project config first (.coding-agent/llm-aliases.yml)
        # Use ProjectRootDetector to find the actual project root
        begin
          project_root = Atoms::ProjectRootDetector.find_project_root
          project_config_path = File.join(project_root, PROJECT_CONFIG_PATH)
          if File.exist?(project_config_path)
            return load_yaml_config(project_config_path)
          end
        rescue => e
          # If we can't find project root, just continue to other options
          # This might happen when running outside a project context
        end
        
        # Check user config second (~/.config/coding-agent-tools/llm-aliases.yml)
        user_config_path = user_aliases_config_path
        if File.exist?(user_config_path)
          return load_yaml_config(user_config_path)
        end
        
        # Fallback to hardcoded defaults
        DEFAULT_ALIASES.dup
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
        YAML.load_file(config_path) || {}
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

        global_aliases[alias_name.to_s] || global_aliases[alias_name.to_sym]
      end

      # Resolve provider-specific alias
      # @param provider [String] The provider name
      # @param model_alias [String] The model alias
      # @return [String, nil] Resolved model name or nil if not found
      def resolve_provider_alias(provider, model_alias)
        provider_aliases = @aliases_config.dig("providers", provider)
        return nil unless provider_aliases

        provider_aliases[model_alias.to_s] || provider_aliases[model_alias.to_sym]
      end
    end
  end
end
