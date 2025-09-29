# frozen_string_literal: true

module Ace
  module LLM
    module Atoms
      # EnvReader provides environment variable reading utilities
      # This is an atom - it has no dependencies on other parts of this gem
      class EnvReader
        # Load .env files from .ace cascade and optionally set to ENV
        # Following ace patterns, searches for .env in:
        # - ./.ace/llm/.env (current project)
        # - ../.ace/llm/.env (parent dirs up to root)
        # - ~/.ace/llm/.env (user home)
        # - ./.ace/.env (fallback)
        # - ~/.ace/.env (fallback)
        # @param set_env [Boolean] Whether to set loaded vars to ENV (default: false for clean isolation)
        # @return [Hash] All loaded environment variables
        def self.load_env_cascade(set_env: false)
          loaded_vars = load_env_cascade_without_setting

          if set_env && defined?(Ace::Core)
            # Only set to ENV if explicitly requested
            Ace::Core::Molecules::EnvLoader.set_environment(loaded_vars, overwrite: true)
          end

          loaded_vars
        end
        # Get an environment variable value
        # @param key [String] Environment variable name
        # @param default [String, nil] Default value if not found
        # @return [String, nil] The environment variable value or default
        def self.get(key, default = nil)
          ENV.fetch(key, default)
        end

        # Get an environment variable value, raising if not found
        # @param key [String] Environment variable name
        # @return [String] The environment variable value
        # @raise [KeyError] If the environment variable is not set
        def self.get!(key)
          ENV.fetch(key)
        rescue KeyError
          raise KeyError, "Environment variable '#{key}' is not set"
        end

        # Check if an environment variable is set
        # @param key [String] Environment variable name
        # @return [Boolean] True if the variable is set, false otherwise
        def self.set?(key)
          ENV.key?(key)
        end

        # Check if an environment variable is set and not empty
        # @param key [String] Environment variable name
        # @return [Boolean] True if the variable is set and not empty
        def self.present?(key)
          value = ENV[key]
          !value.nil? && !value.strip.empty?
        end

        # Get multiple environment variables as a hash
        # @param keys [Array<String>] List of environment variable names
        # @param prefix [String, nil] Optional prefix to prepend to each key
        # @return [Hash<String, String>] Hash of key-value pairs (only includes set variables)
        def self.get_multiple(keys, prefix: nil)
          keys.each_with_object({}) do |key, hash|
            full_key = prefix ? "#{prefix}#{key}" : key
            value = ENV[full_key]
            hash[key] = value if value
          end
        end

        # Get all environment variables matching a pattern
        # @param pattern [Regexp, String] Pattern to match (String will be used as prefix)
        # @return [Hash<String, String>] Matching environment variables
        def self.get_matching(pattern)
          pattern = /^#{Regexp.escape(pattern)}/ if pattern.is_a?(String)

          ENV.select { |key, _| key =~ pattern }
        end

        # Temporarily set environment variables for a block
        # @param vars [Hash<String, String>] Variables to set temporarily
        # @yield Block to execute with temporary variables
        # @return [Object] The return value of the block
        def self.with_env(vars)
          original_values = {}

          # Store original values and set new ones
          vars.each do |key, value|
            original_values[key] = ENV[key]
            if value.nil?
              ENV.delete(key)
            else
              ENV[key] = value.to_s
            end
          end

          yield
        ensure
          # Restore original values
          original_values.each do |key, value|
            if value.nil?
              ENV.delete(key)
            else
              ENV[key] = value
            end
          end
        end

        # Get API key for a provider from environment
        # First checks ENV, then loads from .ace/.env cascade if needed
        # @param provider [String] Provider name (e.g., "google", "openai")
        # @return [String, nil] API key if found
        def self.get_api_key(provider)
          # Determine which keys to look for based on provider
          key_names = case provider.downcase
          when "google", "gemini"
            ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
          when "openai"
            ["OPENAI_API_KEY"]
          when "anthropic"
            ["ANTHROPIC_API_KEY"]
          when "mistral"
            ["MISTRAL_API_KEY"]
          when "together", "togetherai"
            ["TOGETHER_API_KEY", "TOGETHERAI_API_KEY"]
          when "lmstudio"
            return nil # No API key needed for local
          else
            # Try generic pattern
            ["#{provider.upcase}_API_KEY"]
          end

          # First check ENV for any of the keys
          key_names.each do |key_name|
            value = ENV[key_name]
            return value if value && !value.strip.empty?
          end

          # If not in ENV, load from .ace/.env cascade (without polluting ENV)
          loaded_vars = load_env_cascade_without_setting

          # Check loaded vars for any of the keys
          key_names.each do |key_name|
            value = loaded_vars[key_name]
            return value if value && !value.strip.empty?
          end

          nil
        end

        # Load .env files from cascade without setting ENV
        # This is used internally for on-demand key loading
        # @return [Hash] Loaded environment variables
        def self.load_env_cascade_without_setting
          return {} unless defined?(Ace::Core)

          loaded_vars = {}

          begin
            # Find all .env files in cascade
            discovery = Ace::Core::ConfigDiscovery.new

            # Look for llm-specific env files first
            llm_env_files = discovery.find_all_config_files("llm/.env")

            # Also check for general .ace/.env as fallback
            general_env_files = discovery.find_all_config_files(".env")

            # Combine and deduplicate (llm-specific takes precedence)
            all_files = (general_env_files + llm_env_files).uniq

            # Load files (later files override earlier ones)
            all_files.each do |file|
              next unless File.exist?(file)
              vars = Ace::Core::Molecules::EnvLoader.load_file(file)
              loaded_vars.merge!(vars) if vars
            end

            loaded_vars
          rescue LoadError
            # ace-core not available, skip .env loading
            {}
          rescue => e
            # Log warning but don't fail
            warn "Warning: Failed to load .env files: #{e.message}" if ENV["DEBUG"]
            {}
          end
        end
      end
    end
  end
end