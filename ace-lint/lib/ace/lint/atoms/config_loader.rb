# frozen_string_literal: true

require 'yaml'

module Ace
  module Lint
    module Atoms
      # Pure function to load kramdown configuration
      # Follows ace-* gem pattern: configuration in .ace/lint/kramdown.yml
      class ConfigLoader
        # Standard ace-* configuration paths
        CONFIG_PATHS = [
          '.ace/lint/kramdown.yml',
          '.ace/lint/kramdown.yaml',
          File.expand_path('~/.ace/lint/kramdown.yml'),
          File.expand_path('~/.ace/lint/kramdown.yaml')
        ].freeze

        # Load kramdown configuration
        # Follows ace-core pattern: explicit config files, no hidden defaults
        # @param config_path [String, nil] Override path to config file
        # @return [Hash] Kramdown configuration options
        def self.load(config_path: nil)
          path = config_path || find_config_file

          if path && File.exist?(path)
            load_from_file(path)
          else
            # Return minimal defaults if no config found
            # Users should create .ace/lint/kramdown.yml for customization
            minimal_defaults
          end
        end

        # Find config file using standard ace-* cascade
        # @return [String, nil] Path to config file or nil
        def self.find_config_file
          CONFIG_PATHS.find { |path| File.exist?(path) }
        end

        private

        # Load configuration from YAML file
        # @param path [String] Path to config file
        # @return [Hash] Configuration hash
        def self.load_from_file(path)
          begin
            loaded = YAML.safe_load(File.read(path), permitted_classes: [Symbol], aliases: true)
            symbolize_keys(loaded || {})
          rescue StandardError => e
            warn "Warning: Could not load kramdown config from #{path}: #{e.message}"
            minimal_defaults
          end
        end

        # Convert string keys to symbols (kramdown expects symbols)
        # @param hash [Hash] Hash with string keys
        # @return [Hash] Hash with symbol keys
        def self.symbolize_keys(hash)
          hash.transform_keys { |key| key.to_sym rescue key }
        end

        # Minimal defaults when no config file exists
        # Users should create .ace/lint/kramdown.yml for full control
        # @return [Hash] Minimal kramdown options
        def self.minimal_defaults
          {
            input: 'GFM',
            line_width: 120,
            auto_ids: false,
            hard_wrap: false
          }
        end
      end
    end
  end
end
