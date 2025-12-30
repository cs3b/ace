# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "source_registry"
require "ace/support/fs"
require "ace/core/atoms/deep_merger"

module Ace
  module Nav
    module Molecules
      # Loads configuration from .ace/nav/*.yml files and protocols
      # ADR-022: Defaults come from .ace-defaults/nav/config.yml
      #
      # TODO: Refactor to use Ace::Core.config for user config cascade instead of
      # manual path discovery (find_config_dir). This requires enhancing ace-support-core
      # to support ADR-022 pattern: Ace::Core.config.for_gem('nav') that loads
      # gem defaults from .ace-defaults/ and merges with user cascade.
      class ConfigLoader
        class Error < StandardError; end

        def initialize(config_dir = nil, source_registry: nil)
          @config_dir = find_config_dir(config_dir)
          @configs = {}
          @protocols = nil  # Lazy load protocols
          @source_registry = source_registry || SourceRegistry.new
        end

        # Load main settings configuration
        # ADR-022: Loads defaults from .ace-defaults/, merges user config
        # @return [Hash] Configuration with defaults and user overrides
        def load_settings
          # Return cached if already loaded
          return @configs["settings"] if @configs.key?("settings")

          # Load defaults from gem's .ace-defaults/nav/config.yml
          gem_defaults = load_example_config

          # Load user config from .ace/nav/config.yml cascade
          # Fallback to settings.yml for backward compatibility (deprecated)
          user_config = if @config_dir
                          config_path = File.join(@config_dir, "config.yml")
                          legacy_path = File.join(@config_dir, "settings.yml")

                          if File.exist?(config_path)
                            load_yaml_file(config_path)
                          elsif File.exist?(legacy_path)
                            warn "DEPRECATION: #{legacy_path} is deprecated, rename to config.yml"
                            load_yaml_file(legacy_path)
                          else
                            {}
                          end
                        else
                          {}
                        end

          # Deep merge: user config over gem defaults
          @configs["settings"] = Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
        end

        # Load defaults from .ace-defaults/nav/config.yml
        # ADR-022: .ace-defaults/ is the single source of truth for defaults
        # @return [Hash] Default configuration from example file
        # @raise [Error] If default config file is missing or invalid (gem packaging error)
        def load_example_config
          # Use relative path from this file to gem root (4 levels up from molecules/)
          gem_root = File.expand_path("../../../..", __dir__)
          example_path = File.join(gem_root, ".ace-defaults", "nav", "config.yml")

          # ADR-022: Missing .ace-defaults/ file is a packaging error, not a fallback case
          unless File.exist?(example_path)
            raise Error, "Default config not found: #{example_path}. " \
                         "This is a gem packaging error - .ace-defaults/ must be included in the gem."
          end

          # ADR-022: Parse errors in .ace-defaults/ are also packaging errors - don't mask them
          load_yaml_file_strict(example_path)
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

        # Get the type of a protocol (cmd or file)
        # @param protocol_name [String] The protocol name (e.g., "task", "wfi")
        # @return [String] Protocol type: "cmd" for command delegation, "file" for file-based (default)
        def protocol_type(protocol_name)
          protocol_config = load_protocol_config(protocol_name)
          protocol_config["type"] || "file"
        end

        private

        def discover_project_protocol_dirs
          dirs = []

          # Use directory traverser to find all .ace directories up to project root
          traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new(start_path: Dir.pwd)
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

        def load_yaml_file(path)
          content = File.read(path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          warn "Warning: Failed to load config from #{path}: #{e.message}"
          {}
        end

        # Load YAML without masking parse errors - for .ace-defaults/ defaults
        # ADR-022: Parse errors in gem defaults indicate packaging issues
        # @param path [String] Path to YAML file
        # @return [Hash] Parsed YAML content
        # @raise [Error] If file cannot be parsed
        def load_yaml_file_strict(path)
          content = File.read(path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue Psych::SyntaxError => e
          raise Error, "Invalid YAML in default config #{path}: #{e.message}. " \
                       "This is a gem packaging error."
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