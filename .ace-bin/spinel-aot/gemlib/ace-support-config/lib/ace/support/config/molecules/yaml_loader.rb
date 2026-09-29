# frozen_string_literal: true

require "fileutils"

module Ace
  module Support
    module Config
      module Molecules
        # YAML file loading with error handling
        class YamlLoader
          # Load YAML from file
          # @param filepath [String] Path to YAML file
          # @return [Models::Config] Loaded configuration
          # @raise [ConfigNotFoundError] if file doesn't exist
          # @raise [YamlParseError] if YAML is invalid
          def self.load_file(filepath)
            unless File.exist?(filepath)
              raise ConfigNotFoundError, "Configuration file not found: #{filepath}"
            end

            content = File.read(filepath)
            data = Atoms::YamlParser.parse(content)

            Models::Config.new(data, source: filepath)
          rescue IOError, SystemCallError => e
            raise ConfigNotFoundError, "Failed to read file #{filepath}: #{e.message}"
          end

          # Load YAML from file, return empty config if not found
          # @param filepath [String] Path to YAML file
          # @return [Models::Config] Loaded configuration or empty config
          def self.load_file_safe(filepath)
            load_file(filepath)
          rescue ConfigNotFoundError
            Models::Config.new({}, source: "#{filepath} (not found)")
          end

          # Save configuration to YAML file
          # @param config [Models::Config, Hash] Configuration to save
          # @param filepath [String] Path to save to
          # @raise [IOError] if save fails
          def self.save_file(config, filepath)
            data = config.is_a?(Models::Config) ? config.data : config
            yaml_content = Atoms::YamlParser.dump(data)

            # Create directory if it doesn't exist
            dir = File.dirname(filepath)
            FileUtils.mkdir_p(dir) unless File.directory?(dir)

            File.write(filepath, yaml_content)
          rescue IOError, SystemCallError => e
            raise IOError, "Failed to save file #{filepath}: #{e.message}"
          end

          # Load and merge multiple YAML files
          # @param filepaths [Array<String>] Paths to YAML files
          # @param merge_strategy [Symbol] How to merge arrays (:replace, :concat, :union)
          # @return [Models::Config] Merged configuration
          def self.load_and_merge(*filepaths, merge_strategy: :replace)
            configs = filepaths.flatten.map do |filepath|
              load_file_safe(filepath)
            end

            return Models::Config.new({}, source: "empty") if configs.empty?

            # Merge all configs using the specified strategy
            merged_data = configs.map(&:data).reduce({}) do |result, data|
              Atoms::DeepMerger.merge(result, data, array_strategy: merge_strategy)
            end

            Models::Config.new(
              merged_data,
              source: "merged(#{filepaths.join(", ")})",
              merge_strategy: merge_strategy
            )
          end
        end
      end
    end
  end
end
