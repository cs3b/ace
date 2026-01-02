# frozen_string_literal: true

require "yaml"
require "ace/config"

module Ace
  module Taskflow
    module Molecules
      # Load configuration using Ace::Config.create() API
      # Follows ADR-022: Configuration Default and Override Pattern
      #
      # Configuration priority (highest to lowest):
      # 1. CLI options (handled by commands)
      # 2. Project config: .ace/taskflow/config.yml (nearest wins)
      # 3. User config: ~/.ace/taskflow/config.yml
      # 4. Gem defaults: ace-taskflow/.ace-defaults/taskflow/config.yml
      class ConfigLoader
        # Load gem defaults (cached for performance)
        # @return [Hash] Default configuration from gem
        def self.load_gem_defaults
          @gem_defaults ||= load_config_from_resolver
        end

        # Reset cached gem defaults (for testing)
        def self.reset_gem_defaults!
          @gem_defaults = nil
        end

        # Load configuration from cascade
        # Uses Ace::Config.create() for consistent cascade handling
        # @return [Hash] Merged configuration
        def self.load
          # Always reload to pick up user overrides (don't use cached defaults)
          load_config_from_resolver
        end

        # Internal: Load config from resolver
        # @return [Hash] Configuration from cascade
        def self.load_config_from_resolver
          gem_root = Gem.loaded_specs["ace-taskflow"]&.gem_dir ||
                     File.expand_path("../../../..", __dir__)

          resolver = Ace::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_namespace("taskflow").data
          taskflow_section = config["taskflow"] || config
          extract_taskflow_config(taskflow_section)
        rescue Ace::Config::YamlParseError => e
          warn "Warning: Failed to parse taskflow config: #{e.message}"
          # Fall back to gem defaults only
          load_gem_defaults_only
        end
        private_class_method :load_config_from_resolver

        # Load only gem defaults (for fallback on errors)
        def self.load_gem_defaults_only
          gem_root = Gem.loaded_specs["ace-taskflow"]&.gem_dir ||
                     File.expand_path("../../../..", __dir__)
          default_file = File.join(gem_root, ".ace-defaults", "taskflow", "config.yml")

          return {} unless File.exist?(default_file)

          content = YAML.safe_load_file(default_file, permitted_classes: [], aliases: true)
          taskflow_section = content&.dig("taskflow") || {}
          extract_taskflow_config(taskflow_section)
        rescue StandardError
          {}
        end
        private_class_method :load_gem_defaults_only

        # Load specific configuration section
        # @param section [String] Section name (e.g., "taskflow", "idea")
        # @return [Hash] Configuration section
        def self.load_section(section)
          full_config = load
          full_config[section] || {}
        end

        # Get configuration value by path
        # @param path [String] Dot-separated path (e.g., "taskflow.defaults.idea_location")
        # @return [Object] Configuration value
        def self.get(path)
          parts = path.split(".")
          config = load

          parts.each do |part|
            config = config[part]
            return nil if config.nil?
          end

          config
        end

        # Find root directory from configuration
        # Uses ace-core to detect project root, then finds taskflow directory within it
        # @return [String] Root directory path
        # @raise [RuntimeError] If not in a project or taskflow directory not found
        def self.find_root
          # 1. Find project root using ace-core (provides ace-specific defaults)
          require "ace/core/config_discovery"
          project_root = Ace::Core::ConfigDiscovery.project_root

          unless project_root
            raise "Not in an ACE project. No project root found from #{Dir.pwd}"
          end

          # 2. Get configured taskflow root directory name
          config = load
          root_dir = config["root"] || ".ace-taskflow"

          # 3. Build absolute path: project_root + taskflow_root
          # Handle absolute paths in configuration (for special cases)
          taskflow_root = if root_dir.start_with?("~")
            File.expand_path(root_dir)
          elsif root_dir.start_with?("/")
            root_dir
          else
            File.join(project_root, root_dir)
          end

          # 4. Validate it exists
          unless Dir.exist?(taskflow_root)
            raise "Taskflow directory not found: #{taskflow_root}. Run 'ace-taskflow init' to create it."
          end

          taskflow_root
        end

        # Extract taskflow configuration with backward compatibility mapping
        # Supports both new format (taskflow.root) and old format (taskflow.directories.root)
        def self.extract_taskflow_config(taskflow_section)
          config = {}

          # Map configuration structure with backward compatibility
          # Support both new format (taskflow.root) and old format (taskflow.directories.root)
          config["root"] = if taskflow_section["root"]
            # New format: taskflow.root (preferred)
            taskflow_section["root"]
          elsif taskflow_section["directories"] && taskflow_section["directories"]["root"]
            # Old format: taskflow.directories.root (deprecated but supported)
            taskflow_section["directories"]["root"]
          end

          # Extract directory configuration (support both old flat and new nested formats)
          if taskflow_section["directories"]
            config["directories"] = taskflow_section["directories"]
            # Also set task_dir from directories.tasks for backward compatibility
            config["task_dir"] = taskflow_section["directories"]["tasks"] if taskflow_section["directories"]["tasks"]
          end

          # Top-level task_dir takes precedence (can override directories.tasks)
          config["task_dir"] = taskflow_section["task_dir"] if taskflow_section["task_dir"]

          config["active_strategy"] = taskflow_section["active_strategy"] if taskflow_section["active_strategy"]
          config["allow_multiple_active"] = taskflow_section["allow_multiple_active"] unless taskflow_section["allow_multiple_active"].nil?

          if taskflow_section["references"]
            config["references"] = taskflow_section["references"]
          end

          if taskflow_section["defaults"]
            config["defaults"] = taskflow_section["defaults"]
          end

          # Include idea and task sections if present
          if taskflow_section["idea"]
            config["idea"] = taskflow_section["idea"]
            # Merge idea defaults into main defaults
            if taskflow_section["idea"]["defaults"]
              config["defaults"] ||= {}
              config["defaults"]["git_commit"] = taskflow_section["idea"]["defaults"]["git_commit"] unless taskflow_section["idea"]["defaults"]["git_commit"].nil?
              config["defaults"]["llm_enhance"] = taskflow_section["idea"]["defaults"]["llm_enhance"] unless taskflow_section["idea"]["defaults"]["llm_enhance"].nil?
            end
          end

          config["task"] = taskflow_section["task"] if taskflow_section["task"]
          config["tasks"] = taskflow_section["tasks"] if taskflow_section["tasks"]
          config["release"] = taskflow_section["release"] if taskflow_section["release"]
          config["params"] = taskflow_section["params"] if taskflow_section["params"]
          config["status"] = taskflow_section["status"] if taskflow_section["status"]
          config["terminal_statuses"] = taskflow_section["terminal_statuses"] if taskflow_section["terminal_statuses"]

          # Preserve taskflow nested section for Configuration access patterns
          # This allows config.dig("taskflow", "key") to work
          config["taskflow"] = taskflow_section

          config
        end
      end
    end
  end
end