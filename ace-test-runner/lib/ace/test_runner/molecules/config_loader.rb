# frozen_string_literal: true

require "yaml"
require "ostruct"

begin
  require "ace/core"
rescue LoadError
  # ace-core not available, will use fallback config loading
end

module Ace
  module TestRunner
    module Molecules
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

        DEFAULT_CONFIG = {
          version: 1,
          patterns: {
            # Support both test/unit/atoms and test/atoms structures
            atoms: "test/{unit/,}atoms/**/*_test.rb",
            molecules: "test/{unit/,}molecules/**/*_test.rb",
            organisms: "test/{unit/,}organisms/**/*_test.rb",
            models: "test/{unit/,}models/**/*_test.rb",
            integration: "test/integration/**/*_test.rb",
            system: "test/system/**/*_test.rb"
          },
          groups: {
            unit: %w[atoms molecules organisms models],
            all: %w[unit integration system],
            quick: %w[atoms molecules]
          },
          defaults: {
            reporter: "progress",
            color: "auto",
            fail_fast: false,
            save_reports: true,
            report_dir: "test-reports"
          },
          failure_limits: {
            max_display: 7
          }
        }.freeze

        def load(config_path = nil)
          config = if config_path && File.exist?(config_path)
            load_from_file(config_path)
          else
            find_and_load_config || deep_copy(DEFAULT_CONFIG)
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

        def find_and_load_config
          # Try ace-core configuration cascade first
          if defined?(Ace::Core::ConfigDiscovery)
            discovery = Ace::Core::ConfigDiscovery.new
            DEFAULT_CONFIG_PATHS.each do |rel_path|
              # Strip .ace/ prefix since ConfigDiscovery searches .ace directories automatically
              search_path = rel_path.sub(/^\.ace\//, '')
              config_file = discovery.find_config_file(search_path)
              if config_file && File.exist?(config_file)
                puts "Loading configuration from: #{config_file}" if ENV["DEBUG"]
                return load_from_file(config_file)
              end
            end
          end

          # Fallback to current directory only
          config_file = DEFAULT_CONFIG_PATHS.find { |path| File.exist?(path) }
          return nil unless config_file

          puts "Loading configuration from: #{config_file}" if ENV["DEBUG"]
          load_from_file(config_file)
        end

        def load_from_file(path)
          content = File.read(path)
          YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)
        rescue StandardError => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          warn "Using default configuration"
          deep_copy(DEFAULT_CONFIG)
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
          # Ensure all sections exist
          config[:patterns] ||= deep_copy(DEFAULT_CONFIG[:patterns])
          config[:groups] ||= deep_copy(DEFAULT_CONFIG[:groups])
          config[:defaults] ||= deep_copy(DEFAULT_CONFIG[:defaults])
          config[:failure_limits] ||= deep_copy(DEFAULT_CONFIG[:failure_limits])
          config[:execution] ||= {}

          # Merge with defaults for missing values
          config[:patterns] = deep_copy(DEFAULT_CONFIG[:patterns]).merge(config[:patterns])
          config[:groups] = deep_copy(DEFAULT_CONFIG[:groups]).merge(config[:groups])
          config[:defaults] = deep_copy(DEFAULT_CONFIG[:defaults]).merge(config[:defaults])
          config[:failure_limits] = deep_copy(DEFAULT_CONFIG[:failure_limits]).merge(config[:failure_limits])

          config
        end

        def deep_copy(obj)
          Marshal.load(Marshal.dump(obj))
        end
      end
    end
  end
end