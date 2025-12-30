# frozen_string_literal: true

require "yaml"
require "ostruct"
require "ace/config"

module Ace
  module TestRunner
    module Molecules
      # Load configuration using ace-core patterns
      # Follows ADR-022: Configuration Default and Override Pattern
      #
      # Configuration priority (highest to lowest):
      # 1. CLI options (handled by merge_with_options)
      # 2. Explicit config_path if provided
      # 3. Project config: .ace/test/runner.yml (nearest wins via cascade)
      # 4. User config: ~/.ace/test/runner.yml
      # 5. Gem defaults: ace-test-runner/.ace-defaults/test-runner/config.yml
      class ConfigLoader
        DEFAULT_CONFIG_PATHS = [
          ".ace/test/runner.yml",
          ".ace/test/runner.yaml",
          ".ace/test.yml",
          ".ace/test.yaml",
          ".ace/test-runner.yml",
          ".ace/test-runner.yaml",
          "test-runner.yml",
          "test-runner.yaml"
        ].freeze

        # Load gem defaults from .ace-defaults/test-runner/config.yml
        # This file is shipped with the gem and is the single source of truth
        # Per ADR-022: gem MUST include .ace-defaults/ - missing file is a packaging error
        # @return [Hash] Default configuration from gem
        # @raise [RuntimeError] If default config file is missing (gem packaging error)
        def self.load_gem_defaults
          @gem_defaults ||= begin
            gem_root = File.expand_path("../../../..", __dir__)
            default_file = File.join(gem_root, ".ace-defaults", "test-runner", "config.yml")

            unless File.exist?(default_file)
              raise "Default config not found: #{default_file}. " \
                    "This is a gem packaging error - .ace-defaults/ must be included in the gem."
            end

            content = YAML.safe_load_file(default_file, permitted_classes: [], symbolize_names: true, aliases: true)
            content || {}
          end
        end

        # Reset cached gem defaults (for testing)
        def self.reset_gem_defaults!
          @gem_defaults = nil
        end

        def load(config_path = nil)
          # Start with gem defaults
          config = deep_copy(self.class.load_gem_defaults)

          if config_path && File.exist?(config_path)
            # Explicit config path provided - merge over defaults
            user_config = load_from_file(config_path)
            config = Ace::Config::Atoms::DeepMerger.merge(config, user_config)
          else
            # Apply cascade: home config, then walk up from current directory
            cascade_configs.each do |path|
              if File.exist?(path)
                puts "Loading configuration from: #{path}" if ENV["DEBUG"]
                user_config = load_from_file(path)
                config = Ace::Config::Atoms::DeepMerger.merge(config, user_config)
              end
            end
          end

          validate_config(config)
          normalize_config(config)
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

        # Build cascade paths from home directory up through current directory hierarchy
        # Returns paths in order from lowest to highest priority
        def cascade_configs
          paths = []

          # User-level config (lowest priority in cascade)
          home_config = File.join(Dir.home, ".ace", "test", "runner.yml")
          paths << home_config

          # Walk from current directory up, collecting project configs
          project_paths = []
          current = Dir.pwd
          while current != "/" && current != File.dirname(current)
            DEFAULT_CONFIG_PATHS.each do |rel_path|
              full_path = File.join(current, rel_path)
              project_paths << full_path if File.exist?(full_path)
            end
            current = File.dirname(current)
          end

          # Add project paths in reverse order (furthest ancestor first, current last)
          paths.concat(project_paths.reverse)

          paths.uniq
        end

        def load_from_file(path)
          YAML.safe_load_file(path, permitted_classes: [], symbolize_names: true, aliases: true) || {}
        rescue StandardError => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          {}
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
          config[:groups] ||= {}
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
