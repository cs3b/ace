# frozen_string_literal: true

require "dotenv"

module CodingAgentTools
  module Atoms
    # EnvReader provides environment variable reading utilities
    # This is an atom - it has no dependencies on other parts of this gem
    class EnvReader
      # Load environment variables from .env file
      # @param path [String] Path to .env file (default: ".env")
      # @param overload [Boolean] Whether to overwrite existing env vars
      # @return [Hash] The loaded environment variables
      def self.load_env_file(path = ".env", overload: false)
        return {} unless File.exist?(path)

        if overload
          Dotenv.overload(path)
        else
          Dotenv.load(path)
        end
      end

      # Find and load .env file from standardized locations
      # Priority order:
      # 1. Project-specific: <project_root>/.coding-agent/.env
      # 2. Global: ~/.coding-agent/.env
      # @param project_root [String] The project root directory (default: current working directory)
      # @param overload [Boolean] Whether to overwrite existing env vars
      # @return [Hash] The loaded environment variables
      def self.load_standardized_env(project_root: Dir.pwd, overload: false)
        # Check for deprecated .env in project root
        deprecated_env = File.join(project_root, ".env")
        if File.exist?(deprecated_env)
          warn "[DEPRECATION WARNING] Found .env in project root. Please migrate to .coding-agent/.env"
          warn "Run: mkdir -p .coding-agent && mv .env .coding-agent/.env"
        end

        # Priority 1: Project-specific .coding-agent/.env
        project_env = File.join(project_root, ".coding-agent", ".env")
        if File.exist?(project_env)
          return load_env_file(project_env, overload: overload)
        end

        # Priority 2: Global ~/.coding-agent/.env
        global_env = File.expand_path("~/.coding-agent/.env")
        if File.exist?(global_env)
          return load_env_file(global_env, overload: overload)
        end

        # No .env file found in standard locations
        {}
      end

      # Find the path to the .env file in standardized locations
      # @param project_root [String] The project root directory
      # @return [String, nil] Path to the .env file or nil if not found
      def self.find_standardized_env_path(project_root: Dir.pwd)
        # Priority 1: Project-specific .coding-agent/.env
        project_env = File.join(project_root, ".coding-agent", ".env")
        return project_env if File.exist?(project_env)

        # Priority 2: Global ~/.coding-agent/.env
        global_env = File.expand_path("~/.coding-agent/.env")
        return global_env if File.exist?(global_env)

        nil
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
    end
  end
end
