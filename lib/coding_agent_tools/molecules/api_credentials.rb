# frozen_string_literal: true

require_relative '../atoms/env_reader'

module CodingAgentTools
  module Molecules
    # APICredentials manages API key retrieval and configuration
    # This is a molecule - it composes the EnvReader atom
    class APICredentials
      # Singleton configuration store
      @config = {}

      class << self
        attr_accessor :config

        # Configure API credentials
        # @yield [config] Configuration block
        # @yieldparam config [Hash] Configuration hash
        def configure
          yield @config if block_given?
        end

        # Reset configuration to defaults
        def reset!
          @config = {}
        end
      end

      # Initialize with optional configuration
      # @param env_key_name [String, nil] Environment variable name for the API key
      # @param env_file_path [String, nil] Path to .env file to load
      def initialize(env_key_name: nil, env_file_path: nil)
        @env_key_name = env_key_name
        @env_file_path = env_file_path || find_standardized_env_file

        # Load .env file if it exists
        load_env_file if @env_file_path
      end

      # Get the API key from configuration or environment
      # @return [String] The API key
      # @raise [KeyError] If no API key is found or env_key_name not set
      def api_key
        raise KeyError, 'env_key_name not set. Please provide it during initialization.' if @env_key_name.nil?

        # First check singleton configuration
        return self.class.config[@env_key_name] if self.class.config[@env_key_name]

        # Then check environment variable
        key = Atoms::EnvReader.get(@env_key_name)

        if key.nil? || key.strip.empty?
          raise KeyError,
            "API key not found. Please set #{@env_key_name} environment variable or configure it via APICredentials.configure"
        end

        key
      end

      # Check if API key is available
      # @return [Boolean] True if API key is present
      def api_key_present?
        return false if @env_key_name.nil?

        # Check singleton configuration first
        config_value = self.class.config[@env_key_name]
        return true if config_value && !config_value.to_s.strip.empty?

        # Then check environment
        Atoms::EnvReader.present?(@env_key_name)
      end

      # Get API key with a specific prefix
      # @param prefix [String] Prefix to add to the key (e.g., "Bearer ")
      # @return [String] The prefixed API key
      def api_key_with_prefix(prefix)
        "#{prefix}#{api_key}"
      end

      # Load API credentials from a specific environment
      # @param environment [String] Environment name (e.g., "development", "production")
      # @return [Hash] All API-related environment variables for that environment
      def load_for_environment(environment)
        prefix = "#{environment.upcase}_"

        # Get all matching environment variables
        env_vars = Atoms::EnvReader.get_matching(prefix)

        # Filter to API-related variables
        env_vars.select do |key, _|
          key.include?('API') || key.include?('KEY') || key.include?('TOKEN')
        end
      end

      private

      # Load environment variables from .env file
      def load_env_file
        Atoms::EnvReader.load_env_file(@env_file_path)
      end

      # Find .env file in standardized locations
      # @return [String, nil] Path to .env file or nil if not found
      def find_standardized_env_file
        # Find project root by looking for .git directory or other markers
        project_root = find_project_root

        # Use the EnvReader's standardized path finding
        Atoms::EnvReader.find_standardized_env_path(project_root: project_root)
      end

      # Find the project root directory
      # @return [String] The project root directory path
      def find_project_root
        current_dir = File.expand_path(Dir.pwd)

        loop do
          # Check for common project root indicators
          if File.exist?(File.join(current_dir, '.git')) ||
              File.exist?(File.join(current_dir, 'Gemfile')) ||
              File.exist?(File.join(current_dir, 'package.json')) ||
              File.exist?(File.join(current_dir, '.coding-agent'))
            return current_dir
          end

          parent = File.expand_path(File.dirname(current_dir))
          break if parent == current_dir
          current_dir = parent
        end

        # Fallback to current directory if no project root found
        Dir.pwd
      end
    end
  end
end
