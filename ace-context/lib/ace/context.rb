# frozen_string_literal: true

require 'ace/config'
require 'ace/core'
require 'ace/git'
require_relative 'context/version'

# Main API
require_relative 'context/organisms/context_loader'
require_relative 'context/molecules/preset_manager'
require_relative 'context/molecules/context_file_writer'

module Ace
  module Context
    # Mutex for thread-safe config initialization
    @config_mutex = Mutex.new

    class << self
      # Load context using preset
      # @param preset_name [String] Name of the preset to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_preset(preset_name, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_preset(preset_name)
      end

      # Load multiple presets and merge them
      # @param preset_names [Array<String>] Names of presets to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Merged context data
      def load_multiple_presets(preset_names, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_multiple_presets(preset_names)
      end

      # Inspect configuration of presets/files without loading files or executing commands
      # @param inputs [Array<String>] Names of presets or paths to files to inspect
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Configuration as YAML
      def inspect_config(inputs, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.inspect_config(inputs)
      end

      # List available presets
      # @return [Array<Hash>] List of available presets
      def list_presets
        manager = Molecules::PresetManager.new
        manager.list_presets
      end

      # Load context from file
      # @param path [String] Path to context file
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_file(path, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_file(path)
      end

      # Load with auto-detection
      # @param input [String] File path, inline YAML, or preset name
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Loaded context data
      def load_auto(input, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_auto(input)
      end

      # Load multiple inputs and merge them
      # @param inputs [Array<String>] Array of inputs to load
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Merged context data
      def load_multiple(inputs, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_multiple(inputs)
      end

      # Load multiple inputs (presets and files) and merge them
      # @param preset_names [Array<String>] Names of presets to load
      # @param file_paths [Array<String>] Paths to configuration files
      # @param options [Hash] Additional options
      # @return [Models::ContextData] Merged context data
      def load_multiple_inputs(preset_names, file_paths, options = {})
        loader = Organisms::ContextLoader.new(options)
        loader.load_multiple_inputs(preset_names, file_paths, options)
      end

      # Write context output to file with optional chunking
      # @param context [Models::ContextData] Context to write
      # @param output_path [String] Output file path
      # @param options [Hash] Additional options
      # @return [Hash] Write result with success status
      def write_output(context, output_path, options = {})
        writer = Molecules::ContextFileWriter.new(
          cache_dir: cache_dir,
          chunk_limit: chunk_limit
        )
        writer.write_with_chunking(context, output_path, options)
      end

      # Get configuration for ace-context
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Ace::Config.create() for configuration cascade resolution
      # Thread-safe: uses mutex for initialization
      # @return [Hash] merged configuration hash
      # @example Get current configuration
      #   config = Ace::Context.config
      #   puts config["cache_dir"]  # => ".cache/ace-context"
      def config
        # Fast path: return cached config if already initialized
        return @config if defined?(@config) && @config

        # Thread-safe initialization
        @config_mutex.synchronize do
          @config ||= load_config
        end
      end

      # Reset configuration cache (mainly for testing)
      # Thread-safe: uses mutex to prevent race conditions
      def reset_config!
        @config_mutex.synchronize do
          @config = nil
        end
      end

      # ---- Configuration Helper Methods (ADR-022 compliant) ----
      # These read from config instead of using hardcoded constants

      # Cache directory for context output files
      # @return [String] Cache directory path (default: ".cache/ace-context")
      def cache_dir
        config["cache_dir"] || ".cache/ace-context"
      end

      # Maximum characters before chunking output into multiple files
      # @return [Integer] Chunk limit in characters (default: 150000)
      def chunk_limit
        config["chunk_limit"] || 150_000
      end

      private

      # Load configuration using Ace::Config cascade
      # Resolves gem defaults from .ace-defaults/ and user overrides from .ace/
      # @return [Hash] Merged and transformed configuration
      def load_config
        gem_root = Gem.loaded_specs["ace-context"]&.gem_dir ||
                   File.expand_path("../..", __dir__)

        resolver = Ace::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for context namespace
        config = resolver.resolve_namespace("context")

        # Extract the context section for direct access
        raw_config = config.data["context"] || config.data
        normalize_keys(raw_config)
      rescue Ace::Config::YamlParseError => e
        warn "ace-context: YAML syntax error in configuration"
        warn "  #{e.message}"
        # Fall back to gem defaults
        load_gem_defaults_fallback
      rescue StandardError => e
        warn "ace-context: Failed to load configuration: #{e.message}"
        # Fall back to gem defaults
        load_gem_defaults_fallback
      end

      # Load gem defaults directly as fallback when cascade resolution fails
      # @return [Hash] Defaults hash or empty hash if defaults also fail
      def load_gem_defaults_fallback
        gem_root = Gem.loaded_specs["ace-context"]&.gem_dir ||
                   File.expand_path("../..", __dir__)
        defaults_path = File.join(gem_root, ".ace-defaults", "context", "config.yml")

        return {} unless File.exist?(defaults_path)

        data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
        normalize_keys(data["context"] || data)
      rescue StandardError
        {} # Only return empty hash if even defaults fail to load
      end

      # Normalize hash keys to strings for consistent access
      # @param hash [Hash] Hash with potentially mixed string/symbol keys
      # @return [Hash] Hash with string keys
      def normalize_keys(hash)
        return {} unless hash.is_a?(Hash)

        hash.transform_keys(&:to_s)
      end
    end
  end
end