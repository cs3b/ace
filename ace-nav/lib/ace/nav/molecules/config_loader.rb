# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "source_registry"
require "ace/core/molecules/project_root_finder"
require "ace/core/molecules/directory_traverser"

module Ace
  module Nav
    module Molecules
      # Loads configuration from .ace/nav/*.yml files and protocols
      class ConfigLoader
        DEFAULT_CONFIG = {
          "cache" => {
            "enabled" => false,
            "directory" => ".cache/ace-nav",
            "ttl" => 3600
          },
          "fuzzy" => {
            "enabled" => true,
            "threshold" => 0.6
          },
          "output" => {
            "color" => true,
            "verbose" => false
          }
        }.freeze

        def initialize(config_dir = nil, source_registry: nil)
          @config_dir = find_config_dir(config_dir)
          @configs = {}
          @protocols = nil  # Lazy load protocols
          @source_registry = source_registry || SourceRegistry.new
        end

        # Load main settings configuration
        def load_settings
          load_config("settings.yml", DEFAULT_CONFIG)
        end

        # Load protocol-specific configuration
        def load_protocol_config(protocol)
          protocols = load_protocols
          return protocols[protocol] if protocols[protocol]

          # Fallback to defaults for backward compatibility
          default_protocol_config(protocol)
        end

        # Load all available protocols
        def load_protocols
          return @protocols if @protocols

          @protocols = {}

          # 1. Load from user ~/.ace/nav/protocols/
          load_directory_protocols(File.expand_path("~/.ace/nav/protocols")).each do |protocol_data|
            key = protocol_data["protocol"]
            @protocols[key] = protocol_data if key
          end

          # 2. Load from project .ace/protocols/ hierarchy (highest priority)
          # Find all .ace/protocols directories from current dir up to project root
          discover_project_protocol_dirs.each do |dir|
            load_directory_protocols(dir).each do |protocol_data|
              key = protocol_data["protocol"]
              @protocols[key] = protocol_data if key
            end
          end

          @protocols
        end

        # Get list of valid protocol names
        def valid_protocols
          load_protocols.keys
        end

        # Check if a protocol is valid
        def valid_protocol?(protocol)
          valid_protocols.include?(protocol)
        end

        # Get all available configuration files
        def available_configs
          return [] unless @config_dir && Dir.exist?(@config_dir)

          Dir.glob(File.join(@config_dir, "*.yml")).map do |path|
            File.basename(path, ".yml")
          end
        end

        # Get all discovered protocols with their metadata
        def discovered_protocols
          load_protocols
        end

        # Get sources for a specific protocol
        def sources_for_protocol(protocol)
          @source_registry.sources_for_protocol(protocol)
        end

        private

        def discover_project_protocol_dirs
          dirs = []

          # Use directory traverser to find all .ace directories up to project root
          traverser = Ace::Core::Molecules::DirectoryTraverser.new(start_path: Dir.pwd)
          config_dirs = traverser.find_config_directories

          # Check each .ace directory for a protocols subdirectory
          config_dirs.each do |config_dir|
            protocol_dir = File.join(config_dir, "nav/protocols")
            dirs << protocol_dir if Dir.exist?(protocol_dir)
          end

          dirs
        end

        def load_directory_protocols(dir_path)
          protocols = []
          return protocols unless Dir.exist?(dir_path)

          Dir.glob(File.join(dir_path, "*.yml")).each do |file|
            protocol_data = load_yaml_file(file)
            protocols << protocol_data if protocol_data.is_a?(Hash)
          end

          protocols
        end

        def find_config_dir(config_dir)
          return config_dir if config_dir

          # Search for .ace/nav directory in cascade
          search_paths = [
            File.expand_path("./.ace/nav"),      # Project level
            File.expand_path("~/.ace/nav")        # User level
          ]

          search_paths.find { |path| Dir.exist?(path) }
        end

        def load_config(filename, default_config)
          # Return cached if already loaded
          return @configs[filename] if @configs.key?(filename)

          config = if @config_dir
                     config_path = File.join(@config_dir, filename)
                     if File.exist?(config_path)
                       load_yaml_file(config_path)
                     else
                       default_config
                     end
                   else
                     default_config
                   end

          @configs[filename] = deep_merge(default_config, config)
        end

        def load_yaml_file(path)
          content = File.read(path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          {}
        end

        def deep_merge(hash1, hash2)
          return hash2 unless hash1.is_a?(Hash) && hash2.is_a?(Hash)

          hash1.merge(hash2) do |_key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge(old_val, new_val)
            else
              new_val
            end
          end
        end

        def default_protocol_config(protocol)
          case protocol
          when "wfi"
            {
              "workflows" => {
                "extensions" => [".wfi.md", ".workflow.md"],
                "default_dir" => "workflow-instructions"
              }
            }
          when "tmpl"
            {
              "templates" => {
                "extensions" => [".tmpl.md", ".template.md"],
                "default_dir" => "templates"
              }
            }
          when "guide"
            {
              "guides" => {
                "extensions" => [".guide.md", ".md"],
                "default_dir" => "guides"
              }
            }
          when "sample"
            {
              "samples" => {
                "extensions" => [],
                "default_dir" => "samples"
              }
            }
          when "task"
            {
              "tasks" => {
                "search_paths" => [
                  "dev-taskflow/current/*/tasks",
                  "dev-taskflow/backlog"
                ],
                "extensions" => [".md"],
                "autocorrect" => {
                  "enabled" => true,
                  "pad_zeros" => true
                }
              }
            }
          else
            {}
          end
        end
      end
    end
  end
end