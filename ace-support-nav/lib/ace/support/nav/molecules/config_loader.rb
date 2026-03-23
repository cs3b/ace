# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "source_registry"
require "ace/support/fs"
require "ace/support/config"

module Ace
  module Support
    module Nav
      module Molecules
        # Loads configuration from .ace/nav/*.yml files and protocols
        # ADR-022: Uses Ace::Support::Config.create() for gem defaults + user cascade
        class ConfigLoader
          class Error < StandardError; end

          def initialize(config_dir = nil, source_registry: nil)
            @config_dir = find_config_dir(config_dir)
            @configs = {}
            @protocols = nil  # Lazy load protocols
            @source_registry = source_registry || SourceRegistry.new
          end

          # Load main settings configuration
          # ADR-022: Uses Ace::Support::Config.create() for gem defaults + user cascade
          #
          # NOTE: The "nav" namespace is intentionally preserved (not "support/nav") for
          # backward compatibility with existing user configurations in .ace/nav/config.yml.
          # This allows users upgrading from ace-nav to ace-support-nav to keep their config
          # without migration. See PR #152 review discussion for context.
          #
          # @return [Hash] Configuration with defaults and user overrides
          def load_settings
            # Return cached if already loaded
            return @configs["settings"] if @configs.key?("settings")

            # Load gem defaults via Ace::Support::Config
            # Use centralized gem_root from Nav module (avoids path depth duplication)
            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: Ace::Support::Nav.gem_root
            )

            # Get gem defaults first - uses "nav" namespace for backward compatibility
            gem_defaults = begin
              resolver.resolve_namespace("nav").data
            rescue Ace::Support::Config::YamlParseError => e
              warn "Warning: Failed to parse nav config: #{e.message}" if debug?
              load_gem_defaults_only
            rescue => e
              warn "Warning: Could not load ace-support-nav config: #{e.message}" if debug?
              load_gem_defaults_only
            end

            # Load user config from @config_dir if explicitly set (for testing/override)
            # or use the cascade from resolver
            user_config = if @config_dir
              load_user_config_from_dir(@config_dir)
            else
              # No explicit config_dir - defaults already include cascade
              {}
            end

            # Deep merge: user config over gem defaults
            @configs["settings"] = Ace::Support::Config::Atoms::DeepMerger.merge(gem_defaults, user_config)
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

            # 0. Load from gem defaults (lowest priority)
            gem_defaults_dir = File.join(Ace::Support::Nav.gem_root, ".ace-defaults", "nav", "protocols")
            load_directory_protocols(gem_defaults_dir).each do |protocol_data|
              key = protocol_data["protocol"]
              @protocols[key] = protocol_data if key
            end

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

          # Load user config from explicit config directory
          # @param config_dir [String] Path to .ace/nav directory
          # @return [Hash] User configuration
          def load_user_config_from_dir(config_dir)
            config_path = File.join(config_dir, "config.yml")

            if File.exist?(config_path)
              load_yaml_file(config_path)
            else
              {}
            end
          end

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
          rescue => e
            warn "Warning: Failed to load config from #{path}: #{e.message}"
            {}
          end

          # Load only gem defaults (for fallback on config errors)
          # Delegates to module-level method to avoid duplication
          # @return [Hash] Gem defaults or empty hash
          def load_gem_defaults_only
            Ace::Support::Nav.load_gem_defaults_fallback
          end

          # Check if debug mode is enabled
          # @return [Boolean] True if debug mode is enabled
          def debug?
            ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
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
end
