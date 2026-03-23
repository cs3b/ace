# frozen_string_literal: true

require "ace/support/config"
require "ace/core"
require "ace/git"
require_relative "bundle/version"

# Define error hierarchy before loading components (they reference these classes)
module Ace
  module Bundle
    # Base error class for all ace-bundle errors
    class Error < StandardError; end

    # Raised when section validation fails
    class SectionValidationError < Error; end

    # Raised when preset loading fails
    class PresetLoadError < Error; end
  end
end

# Main API
require_relative "bundle/organisms/bundle_loader"
require_relative "bundle/molecules/preset_manager"
require_relative "bundle/molecules/bundle_file_writer"

# CLI and commands
require_relative "bundle/cli"

module Ace
  module Bundle
    # Mutex for thread-safe config initialization
    @config_mutex = Mutex.new

    class << self
      # Load bundle using preset
      # @param preset_name [String] Name of the preset to load
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Loaded bundle data
      def load_preset(preset_name, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_preset(preset_name)
      end

      # Load multiple presets and merge them
      # @param preset_names [Array<String>] Names of presets to load
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Merged bundle data
      def load_multiple_presets(preset_names, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_multiple_presets(preset_names)
      end

      # Inspect configuration of presets/files without loading files or executing commands
      # @param inputs [Array<String>] Names of presets or paths to files to inspect
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Configuration as YAML
      def inspect_config(inputs, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.inspect_config(inputs)
      end

      # List available presets
      # @return [Array<Hash>] List of available presets
      def list_presets
        manager = Molecules::PresetManager.new
        manager.list_presets
      end

      # Load bundle from file
      # @param path [String] Path to bundle file
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Loaded bundle data
      def load_file(path, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_file(path)
      end

      # Load with auto-detection
      # @param input [String] File path, inline YAML, or preset name
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Loaded bundle data
      def load_auto(input, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_auto(input)
      end

      # Load multiple inputs and merge them
      # @param inputs [Array<String>] Array of inputs to load
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Merged bundle data
      def load_multiple(inputs, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_multiple(inputs)
      end

      # Load multiple inputs (presets and files) and merge them
      # @param preset_names [Array<String>] Names of presets to load
      # @param file_paths [Array<String>] Paths to configuration files
      # @param options [Hash] Additional options
      # @return [Models::BundleData] Merged bundle data
      def load_multiple_inputs(preset_names, file_paths, options = {})
        loader = Organisms::BundleLoader.new(options)
        loader.load_multiple_inputs(preset_names, file_paths, options)
      end

      # Write bundle output to file with optional chunking
      # @param bundle [Models::BundleData] Bundle to write
      # @param output_path [String] Output file path
      # @param options [Hash] Additional options
      # @return [Hash] Write result with success status
      def write_output(bundle, output_path, options = {})
        writer = Molecules::BundleFileWriter.new(
          cache_dir: cache_dir,
          max_lines: max_lines
        )
        result = writer.write_with_chunking(bundle, output_path, options)

        # Write compression metadata sidecar for downstream tools (e.g., ace-compressor)
        stats = bundle.respond_to?(:metadata) && bundle.metadata&.dig(:compression_stats)
        if stats && result[:success]
          require "json"
          File.write("#{output_path}.meta.json", JSON.generate(stats))
        end

        result
      end

      # Get configuration for ace-bundle
      # Follows ADR-022: Configuration Default and Override Pattern
      # Uses Ace::Support::Config.create() for configuration cascade resolution
      # Thread-safe: uses mutex for initialization
      # @return [Hash] merged configuration hash
      # @example Get current configuration
      #   config = Ace::Bundle.config
      #   puts config["cache_dir"]  # => ".ace-local/bundle"
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

      # Cache directory for bundle output files
      # @return [String] Cache directory path (default: ".ace-local/bundle")
      def cache_dir
        config["cache_dir"] || ".ace-local/bundle"
      end

      # Maximum lines per chunk before splitting output into multiple files
      # @return [Integer] Max lines per chunk (default: 2000)
      def max_lines
        config["max_lines"] || 2_000
      end

      # Line count threshold for auto-format output mode
      # When no explicit --output mode is specified:
      #   - Content below this threshold: displayed inline (stdout)
      #   - Content at or above this threshold: saved to cache file
      # @return [Integer] Auto-format threshold in lines (default: 500, range: 10-10000)
      def auto_format_threshold
        threshold = config["auto_format_threshold"]
        # Ensure valid integer within reasonable bounds (10-10000 lines)
        # - Below 10: too aggressive, would cache almost everything
        # - Above 10000: defeats the purpose of auto-format
        return 500 unless threshold.is_a?(Integer) && threshold.between?(10, 10_000)

        threshold
      end

      # Compressor configuration section from global/project config
      # @return [Hash] compressor config (default: {})
      def compressor_config
        config["compressor"] || {}
      end

      # Default compressor source scope from config
      # @return [String] source scope (default: "off")
      def compressor_source_scope
        compressor_config["source_scope"] || "off"
      end

      # Default compressor mode from config
      # @return [String] compressor mode (default: "exact")
      def compressor_mode
        compressor_config["mode"] || "exact"
      end

      private

      # Load configuration using Ace::Support::Config cascade
      # Resolves gem defaults from .ace-defaults/ and user overrides from .ace/
      # @return [Hash] Merged and transformed configuration
      def load_config
        gem_root = Gem.loaded_specs["ace-bundle"]&.gem_dir ||
          File.expand_path("../..", __dir__)

        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        # Resolve config for bundle namespace
        config = resolver.resolve_namespace("bundle")

        # Extract the bundle section for direct access
        raw_config = config.data["bundle"] || config.data
        normalize_keys(raw_config)
      rescue Ace::Support::Config::YamlParseError => e
        warn "ace-bundle: YAML syntax error in configuration"
        warn "  #{e.message}"
        # Fall back to gem defaults
        load_gem_defaults_fallback
      rescue => e
        warn "ace-bundle: Failed to load configuration: #{e.message}"
        # Fall back to gem defaults
        load_gem_defaults_fallback
      end

      # Load gem defaults directly as fallback when cascade resolution fails
      # @return [Hash] Defaults hash or empty hash if defaults also fail
      def load_gem_defaults_fallback
        gem_root = Gem.loaded_specs["ace-bundle"]&.gem_dir ||
          File.expand_path("../..", __dir__)
        defaults_path = File.join(gem_root, ".ace-defaults", "bundle", "config.yml")

        return {} unless File.exist?(defaults_path)

        data = YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
        normalize_keys(data["bundle"] || data)
      rescue
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
