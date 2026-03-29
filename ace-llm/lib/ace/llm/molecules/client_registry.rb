# frozen_string_literal: true

require "yaml"
require "date"
require "pathname"
require "ace/support/config"
require_relative "../atoms/env_reader"

module Ace
  module LLM
    module Molecules
      # ClientRegistry manages provider configurations and instantiation
      # Loads provider definitions from YAML files and creates client instances dynamically
      class ClientRegistry
        attr_reader :providers, :global_aliases, :model_aliases

        # Initialize the client registry
        def initialize
          @providers = {}
          @loaded_gems = {}
          @global_aliases = {}
          @model_aliases = {}
          load_all_configurations
          build_alias_maps
        end

        # Get a client instance for a provider and model
        # @param provider_name [String] Provider name
        # @param model [String, nil] Model to use (uses default if nil)
        # @param options [Hash] Additional options for client initialization
        # @return [BaseClient] Client instance
        # @raise [ProviderError] If provider not found or cannot be loaded
        def get_client(provider_name, model: nil, **options)
          provider_config = get_provider(provider_name)

          unless provider_config
            raise ProviderError, "Unknown provider: #{provider_name}. Available providers: #{available_providers.join(", ")}"
          end

          # Load the provider's gem if needed
          load_provider_gem(provider_config)

          # Get the class and instantiate
          client_class = resolve_class(provider_config["class"])

          # Merge options with defaults from config
          merged_options = (provider_config["default_options"] || {}).merge(options)

          # Use specified model or default from config
          model ||= provider_config["models"]&.first || "default"

          # Add API key configuration if specified
          if provider_config["api_key"]
            merged_options[:api_key] = resolve_api_key(provider_config["api_key"])
          end

          # Pass backend configurations (base_url, env_key, model_tiers) to client
          if provider_config["backends"]
            merged_options[:backends] = provider_config["backends"]
          end

          client_class.new(model: model, **merged_options)
        end

        # Get provider configuration
        # @param provider_name [String] Provider name
        # @return [Hash, nil] Provider configuration or nil if not found
        def get_provider(provider_name)
          normalized_name = normalize_provider_name(provider_name)
          @providers[normalized_name]
        end

        # Get list of available provider names
        # @return [Array<String>] Provider names
        def available_providers
          @providers.keys.sort
        end

        # Get list of models for a provider
        # @param provider_name [String] Provider name
        # @return [Array<String>, nil] List of models or nil if provider not found
        def models_for_provider(provider_name)
          provider = get_provider(provider_name)
          provider&.fetch("models", [])
        end

        # Check if a provider is available
        # @param provider_name [String] Provider name
        # @return [Boolean] True if provider is registered
        def provider_exists?(provider_name)
          normalized_name = normalize_provider_name(provider_name)
          @providers.key?(normalized_name)
        end

        # Check if a provider's gem is available
        # @param provider_name [String] Provider name
        # @return [Boolean] True if provider gem can be loaded
        def provider_available?(provider_name)
          provider_config = get_provider(provider_name)
          return false unless provider_config

          # Try to load the gem
          begin
            load_provider_gem(provider_config)
            true
          rescue LoadError, NameError
            false
          end
        end

        # List all providers with their status
        # @return [Hash] Provider status information
        def list_providers_with_status
          @providers.map do |name, config|
            {
              name: name,
              models: config["models"] || [],
              gem: config["gem"],
              available: provider_available?(name),
              api_key_required: config.dig("api_key", "required") || false,
              api_key_present: api_key_present?(config["api_key"])
            }
          end
        end

        # Whether provider config marks API key as required.
        # @param provider_name [String]
        # @return [Boolean]
        def provider_api_key_required?(provider_name)
          provider = get_provider(provider_name)
          return false unless provider

          provider.dig("api_key", "required") || false
        end

        # Whether provider has a present API key according to its api_key config.
        # @param provider_name [String]
        # @return [Boolean]
        def provider_api_key_present?(provider_name)
          provider = get_provider(provider_name)
          return false unless provider

          api_key_present?(provider["api_key"])
        end

        # Reload all configurations
        def reload!
          @providers.clear
          @loaded_gems.clear
          @global_aliases.clear
          @model_aliases.clear
          load_all_configurations
          build_alias_maps
        end

        # Resolve an alias to provider:model format
        # @param input [String] The alias or model to resolve
        # @return [String] The resolved provider:model or original input
        def resolve_alias(input)
          input = input.to_s.strip

          # Check if it's already in provider:model format
          if input.include?(":")
            provider_name, model_alias = input.split(":", 2)
            normalized_provider = normalize_provider_name(provider_name)

            # Try to resolve model alias for this provider
            if @model_aliases[normalized_provider] && @model_aliases[normalized_provider][model_alias]
              return "#{provider_name}:#{@model_aliases[normalized_provider][model_alias]}"
            end

            # Auto-resolve: provider:provider → provider:default_model
            normalized_alias = normalize_provider_name(model_alias)
            if normalized_alias == normalized_provider
              default_model = @providers[normalized_provider]&.dig("models")&.first
              return "#{provider_name}:#{default_model}" if default_model
            end

            # Return as-is if no model alias found
            return input
          end

          # Check global aliases
          if @global_aliases[input]
            resolved = @global_aliases[input]

            # If global alias points to provider:model_alias, resolve the model alias too
            if resolved.include?(":")
              provider_name, model_part = resolved.split(":", 2)
              normalized_provider = normalize_provider_name(provider_name)

              # Check if model_part is itself an alias
              if @model_aliases[normalized_provider] && @model_aliases[normalized_provider][model_part]
                return "#{provider_name}:#{@model_aliases[normalized_provider][model_part]}"
              end
            end

            return resolved
          end

          # Return original if no alias found
          input
        end

        # Get all available aliases
        # @return [Hash] Hash with global and model aliases by provider
        def available_aliases
          {
            global: @global_aliases.dup,
            model: @model_aliases.dup
          }
        end

        private

        # Get gem root for config resolution
        # @return [String] Path to gem root directory
        def gem_root
          Gem.loaded_specs["ace-llm"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)
        end

        # Load all provider configurations using Configuration class
        # Uses ProviderConfigReader which handles project -> home -> gem cascade
        def load_all_configurations
          require_relative "../configuration"
          providers = Ace::LLM.providers

          providers.each do |provider_name, config|
            # Validate required fields
            unless config["name"] && config["class"]
              warn "Invalid provider configuration for #{provider_name}: missing 'name' or 'class'"
              next
            end

            normalized_name = normalize_provider_name(config["name"])
            @providers[normalized_name] = config
          end
        rescue => e
          warn "Error loading provider configurations: #{e.message}"
        end

        # Load a single provider with cascade (deep merge)
        # @param resolver [Ace::Support::Config::Organisms::ConfigResolver] Config resolver
        # @param filename [String] Provider config filename (e.g., "anthropic.yml")
        def load_provider_with_cascade(resolver, filename)
          config = resolver.resolve_file(["llm/providers/#{filename}"]).data

          # Validate required fields
          unless config["name"] && config["class"]
            warn "Invalid provider configuration in #{filename}: missing 'name' or 'class'"
            return
          end

          provider_name = normalize_provider_name(config["name"])
          @providers[provider_name] = config
        rescue Ace::Support::Config::YamlParseError => e
          warn "Error parsing provider config #{filename}: #{e.message}"
        rescue => e
          warn "Error loading provider #{filename}: #{e.message}"
        end

        # Normalize provider name for consistency
        # @param name [String] Provider name
        # @return [String] Normalized name
        def normalize_provider_name(name)
          name.to_s.strip.downcase.gsub(/[-_]/, "")
        end

        # Load provider gem if not already loaded
        # @param provider_config [Hash] Provider configuration
        # @raise [LoadError] If gem cannot be loaded
        def load_provider_gem(provider_config)
          gem_name = provider_config["gem"]
          return unless gem_name

          # Check if already loaded
          return if @loaded_gems[gem_name]

          # Try to require the gem
          begin
            require gem_name.tr("-", "/")
            @loaded_gems[gem_name] = true
          rescue LoadError => e
            raise LoadError, "Cannot load provider gem '#{gem_name}': #{e.message}"
          end
        end

        # Resolve class constant from string
        # @param class_name [String] Full class name (e.g., "Ace::LLM::Organisms::GoogleClient")
        # @return [Class] The resolved class
        # @raise [NameError] If class cannot be resolved
        def resolve_class(class_name)
          class_name.split("::").inject(Object) do |mod, name|
            mod.const_get(name)
          end
        rescue NameError => e
          raise NameError, "Cannot resolve class '#{class_name}': #{e.message}"
        end

        # Resolve API key from configuration
        # @param api_key_config [Hash, String, nil] API key configuration
        # @return [String, nil] Resolved API key
        def resolve_api_key(api_key_config)
          return nil if api_key_config.nil?

          # Simple string means direct key
          return api_key_config if api_key_config.is_a?(String)

          # Hash configuration
          if api_key_config.is_a?(Hash)
            if api_key_config["env"]
              # Read from environment variable
              ENV[api_key_config["env"]]
            elsif api_key_config["value"]
              # Direct value (not recommended)
              api_key_config["value"]
            end
          end
        end

        # Check if API key is present
        # @param api_key_config [Hash, String, nil] API key configuration
        # @return [Boolean] True if API key is configured and present
        def api_key_present?(api_key_config)
          return false if api_key_config.nil?

          key = resolve_api_key(api_key_config)
          !key.nil? && !key.empty?
        end

        # Build alias maps from provider configurations
        def build_alias_maps
          @providers.each do |provider_name, config|
            next unless config["aliases"]

            # Process global aliases
            if config["aliases"]["global"]
              config["aliases"]["global"].each do |alias_name, target|
                @global_aliases[alias_name] = target
              end
            end

            # Process model aliases
            if config["aliases"]["model"]
              @model_aliases[provider_name] ||= {}
              config["aliases"]["model"].each do |alias_name, model|
                @model_aliases[provider_name][alias_name] = model
              end
            end
          end
        end
      end
    end
  end
end
