# frozen_string_literal: true

require "yaml"
require "ostruct"
require "ace/support/config"

module Ace
  module TestRunner
    module Molecules
      # Load configuration using Ace::Support::Config.create() API
      # Follows ADR-022: Configuration Default and Override Pattern
      #
      # Configuration priority (highest to lowest):
      # 1. CLI options (handled by merge_with_options)
      # 2. Explicit config_path if provided
      # 3. Project config: .ace/test/runner.yml (nearest wins via cascade)
      # 4. User config: ~/.ace/test/runner.yml
      # 5. Gem defaults: ace-test-runner/.ace-defaults/test-runner/config.yml
      class ConfigLoader
        # Load gem defaults for direct access (used by tests)
        # @return [Hash] Default configuration with symbol keys
        def self.load_gem_defaults
          gem_root = Gem.loaded_specs["ace-test-runner"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_namespace("test-runner").data
          deep_symbolize_keys(config)
        end

        # Reset method for test isolation (no-op since we don't cache at class level)
        def self.reset_gem_defaults!
          # No-op: Ace::Support::Config.create() is called fresh each time
        end

        def load(config_path = nil)
          gem_root = Gem.loaded_specs["ace-test-runner"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          # Get merged config from cascade
          config = resolver.resolve_file(["test-runner/config.yml", "test/runner.yml"]).data

          # If explicit config_path provided, merge it on top
          if config_path && File.exist?(config_path)
            user_config = load_from_file(config_path)
            config = Ace::Support::Config::Atoms::DeepMerger.merge(config, user_config)
          end

          # Convert to symbol keys for backward compatibility
          config = deep_symbolize_keys(config)

          validate_config(config)
          normalize_config(config)
        rescue => e
          warn "Warning: Could not load ace-test-runner config: #{e.message}" if ENV["DEBUG"]
          # Return minimal valid config on error
          normalize_config({version: 1})
        end

        def merge_with_options(config, options)
          merged = deep_copy(config)

          # Override defaults with command-line options
          if options[:format]
            merged[:defaults] ||= {}
            merged[:defaults][:reporter] = options[:format]
          end

          if options.key?(:color)
            merged[:defaults] ||= {}
            merged[:defaults][:color] = options[:color]
          end

          if options.key?(:fail_fast)
            merged[:defaults] ||= {}
            merged[:defaults][:fail_fast] = options[:fail_fast]
          end

          if options[:report_dir]
            merged[:defaults] ||= {}
            merged[:defaults][:report_dir] = options[:report_dir]
          end

          # Override failure limits with command-line options
          if options[:max_display]
            merged[:failure_limits] ||= {}
            merged[:failure_limits][:max_display] = options[:max_display]
          end

          OpenStruct.new(merged)
        end

        private

        def load_from_file(path)
          YAML.safe_load_file(path, permitted_classes: [], aliases: true) || {}
        rescue => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          {}
        end

        # Recursively convert string keys to symbols
        def deep_symbolize_keys(obj)
          self.class.deep_symbolize_keys(obj)
        end

        # Class method version for use in self.load_gem_defaults
        def self.deep_symbolize_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              result[key.to_sym] = deep_symbolize_keys(value)
            end
          when Array
            obj.map { |item| deep_symbolize_keys(item) }
          else
            obj
          end
        end

        def validate_config(config)
          unless config[:version]
            warn "Warning: Configuration missing version field, assuming version 1"
            config[:version] = 1
          end

          if config[:version] > 1
            warn "Warning: Configuration version #{config[:version]} is newer than supported version 1"
          end

          config
        end

        def normalize_config(config)
          # Ensure all sections exist as hashes (defaults already merged in load)
          config[:patterns] ||= {}
          config[:targets] ||= {}
          config[:defaults] ||= {}
          config[:failure_limits] ||= {}
          config[:execution] ||= {}

          config
        end

        def deep_copy(obj)
          Marshal.load(Marshal.dump(obj))
        end
      end
    end
  end
end
