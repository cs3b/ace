# frozen_string_literal: true

require_relative "../molecules/env_loader"
require_relative "../atoms/path_expander"
require_relative "config_resolver"

module Ace
  module Core
    module Organisms
      # Complete environment variable management
      class EnvironmentManager
        attr_reader :root_path, :config

        # Initialize environment manager
        # @param root_path [String] Project root path
        # @param config [Models::Config, nil] Configuration to use
        def initialize(root_path: Dir.pwd, config: nil)
          @root_path = Atoms::PathExpander.expand(root_path)
          @config = config || load_config
        end

        # Load environment variables based on configuration
        # @param overwrite [Boolean] Whether to overwrite existing vars
        # @return [Hash] Variables that were loaded
        def load
          return {} unless should_load_dotenv?

          dotenv_files = get_dotenv_files
          loaded_vars = {}

          dotenv_files.each do |file|
            filepath = resolve_dotenv_path(file)
            next unless filepath

            vars = Molecules::EnvLoader.load_file(filepath)
            loaded_vars.merge!(vars) if vars && !vars.empty?
          end

          # Set all loaded variables
          Molecules::EnvLoader.set_environment(loaded_vars, overwrite: false)
        end

        # Save current environment to .env file
        # @param filepath [String] Path to save to
        # @param keys [Array<String>] Specific keys to save (nil = all)
        # @return [Hash] Variables that were saved
        def save(filepath = ".env", keys: nil)
          filepath = File.join(root_path, filepath) unless Atoms::PathExpander.absolute?(filepath)

          vars_to_save = if keys
                           ENV.to_h.select { |k, _| keys.include?(k) }
                         else
                           ENV.to_h
                         end

          Molecules::EnvLoader.save_file(vars_to_save, filepath)
          vars_to_save
        end

        # Get specific environment variable with fallback
        # @param key [String] Variable name
        # @param default [Object] Default value if not found
        # @return [String, Object] Variable value or default
        def get(key, default = nil)
          ENV.fetch(key, default)
        end

        # Set environment variable
        # @param key [String] Variable name
        # @param value [String] Variable value
        # @return [String] The value that was set
        def set(key, value)
          ENV[key] = value.to_s
        end

        # Check if variable exists
        # @param key [String] Variable name
        # @return [Boolean] true if variable exists
        def key?(key)
          ENV.key?(key)
        end

        # List all .env files that would be loaded
        # @return [Array<String>] Paths to .env files
        def list_dotenv_files
          return [] unless should_load_dotenv?

          dotenv_files = get_dotenv_files
          dotenv_files.map { |file| resolve_dotenv_path(file) }.compact
        end

        private

        # Load configuration
        # @return [Models::Config] Configuration
        def load_config
          resolver = ConfigResolver.new
          resolver.resolve
        end

        # Check if dotenv should be loaded
        # @return [Boolean] true if should load
        def should_load_dotenv?
          config.get("ace", "environment", "load_dotenv") != false
        end

        # Get list of dotenv files from config
        # @return [Array<String>] Dotenv file names
        def get_dotenv_files
          files = config.get("ace", "environment", "dotenv_files")
          return [".env.local", ".env"] if files.nil?

          files.is_a?(Array) ? files : [files]
        end

        # Resolve dotenv file path
        # @param filename [String] Dotenv filename
        # @return [String, nil] Full path if exists
        def resolve_dotenv_path(filename)
          # Try as absolute path first
          if Atoms::PathExpander.absolute?(filename)
            expanded = Atoms::PathExpander.expand(filename)
            return expanded if File.exist?(expanded)
          end

          # Try relative to root
          filepath = File.join(root_path, filename)
          return filepath if File.exist?(filepath)

          # Try in .ace directory
          filepath = File.join(root_path, ".ace", filename)
          return filepath if File.exist?(filepath)

          nil
        end
      end
    end
  end
end