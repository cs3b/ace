# frozen_string_literal: true

module Ace
  module LLM
    module Molecules
      # ProviderLoader handles dynamic loading of provider gems and classes
      class ProviderLoader
        attr_reader :loaded_gems, :load_errors

        def initialize
          @loaded_gems = {}
          @load_errors = {}
        end

        # Load a provider gem
        # @param gem_name [String] Name of the gem to load
        # @param required [Boolean] Whether the gem is required (raises if true and fails)
        # @return [Boolean] True if loaded successfully
        # @raise [LoadError] If required is true and gem cannot be loaded
        def load_gem(gem_name, required: true)
          return true if @loaded_gems[gem_name]

          begin
            # Try standard require first
            require_gem(gem_name)
            @loaded_gems[gem_name] = true
            true
          rescue LoadError => e
            @load_errors[gem_name] = e.message

            if required
              raise LoadError, "Required provider gem '#{gem_name}' could not be loaded: #{e.message}"
            else
              false
            end
          end
        end

        # Load a provider class
        # @param class_name [String] Full class name (e.g., "Ace::LLM::Organisms::GoogleClient")
        # @param gem_name [String, nil] Optional gem to load first
        # @return [Class] The loaded class
        # @raise [NameError] If class cannot be resolved
        # @raise [LoadError] If gem is required but cannot be loaded
        def load_class(class_name, gem_name: nil)
          # Load gem if specified
          load_gem(gem_name, required: true) if gem_name

          # Resolve the class constant
          resolve_constant(class_name)
        end

        # Try to load a provider and return status
        # @param provider_config [Hash] Provider configuration
        # @return [Hash] Status information about the provider
        def try_load_provider(provider_config)
          status = {
            name: provider_config["name"],
            gem: provider_config["gem"],
            class: provider_config["class"],
            loaded: false,
            available: false,
            error: nil
          }

          begin
            # Try to load gem if specified
            if provider_config["gem"]
              gem_loaded = load_gem(provider_config["gem"], required: false)
              status[:gem_loaded] = gem_loaded

              unless gem_loaded
                status[:error] = "Gem '#{provider_config["gem"]}' not available"
                return status
              end
            end

            # Try to resolve class
            klass = resolve_constant(provider_config["class"])
            status[:loaded] = true
            status[:available] = true
            status[:class_object] = klass
          rescue NameError => e
            status[:error] = "Class '#{provider_config["class"]}' not found: #{e.message}"
          rescue => e
            status[:error] = "Error loading provider: #{e.message}"
          end

          status
        end

        # Check if a gem is available (without loading it)
        # @param gem_name [String] Name of the gem
        # @return [Boolean] True if gem is available
        def gem_available?(gem_name)
          # Check if already loaded
          return true if @loaded_gems[gem_name]

          # Try to find the gem in the load path
          gem_path = gem_name.tr("-", "/")

          $LOAD_PATH.any? do |path|
            File.exist?(File.join(path, "#{gem_path}.rb")) ||
              File.directory?(File.join(path, gem_path))
          end
        end

        # Get list of available provider gems
        # @return [Array<String>] List of available ace-llm provider gems
        def available_provider_gems
          gems = []

          # Check for known provider gems
          known_providers = %w[
            ace-llm-google
            ace-llm-openai
            ace-llm-anthropic
            ace-llm-mistral
            ace-llm-togetherai
          ]

          known_providers.each do |gem_name|
            gems << gem_name if gem_available?(gem_name)
          end

          gems
        end

        # Clear loaded gems cache (useful for testing)
        def clear_cache
          @loaded_gems.clear
          @load_errors.clear
        end

        private

        # Require a gem with various strategies
        # @param gem_name [String] Gem name to require
        # @raise [LoadError] If gem cannot be loaded
        def require_gem(gem_name)
          # Try standard gem name first
          begin
            require gem_name
            return
          rescue LoadError
            # Continue to try other strategies
          end

          # Try with underscores instead of hyphens
          gem_path = gem_name.tr("-", "/")
          begin
            require gem_path
            return
          rescue LoadError
            # Continue to try other strategies
          end

          # Try as a path within ace/llm
          begin
            require "ace/llm/#{gem_path}"
            return
          rescue LoadError
            # No more strategies
          end

          # If all strategies failed, raise the original error
          raise LoadError, "Cannot load gem '#{gem_name}'"
        end

        # Resolve a constant from a string
        # @param constant_name [String] Full constant path
        # @return [Class, Module] The resolved constant
        # @raise [NameError] If constant cannot be resolved
        def resolve_constant(constant_name)
          # Handle absolute constant paths (starting with ::)
          if constant_name.start_with?("::")
            constant_name = constant_name[2..]
          end

          # Split and resolve each part
          parts = constant_name.split("::")

          # Start from Object (top-level)
          current = Object

          parts.each do |part|
            unless current.const_defined?(part, false)
              raise NameError, "uninitialized constant #{current}::#{part}"
            end
            current = current.const_get(part, false)
          end

          current
        end
      end
    end
  end
end
