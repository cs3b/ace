# frozen_string_literal: true

require "yaml"

module Ace
  module Taskflow
    module Molecules
      # Load configuration using ace-core patterns
      class ConfigLoader
        DEFAULT_CONFIG = {
          "root" => ".ace-taskflow",
          "task_dir" => "t",
          "active_strategy" => "lowest",
          "allow_multiple_active" => true,
          "references" => {
            "allow_qualified" => true,
            "allow_cross_release" => true
          },
          "defaults" => {
            "idea_location" => "active",
            "task_location" => "active"
          },
          "tasks" => {
            "defaults" => {
              "reschedule_strategy" => "add_next"
            }
          }
        }.freeze

        # Load configuration from cascade
        # @return [Hash] Merged configuration
        def self.load
          config = DEFAULT_CONFIG.dup

          # Look for config files in cascade order
          config_paths = find_config_paths

          config_paths.each do |path|
            if File.exist?(path)
              file_config = load_file(path)
              config = deep_merge(config, file_config)
            end
          end

          config
        end

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
        # @return [String] Root directory path
        def self.find_root
          config = load
          root = config["root"] || DEFAULT_CONFIG["root"]

          # Expand path relative to current directory
          if root.start_with?("~")
            File.expand_path(root)
          elsif root.start_with?("/")
            root
          else
            File.join(Dir.pwd, root)
          end
        end

        private

        def self.find_config_paths
          paths = []

          # Start from current directory and walk up
          current = Dir.pwd
          while current != "/" && current != File.dirname(current)
            config = File.join(current, ".ace", "taskflow", "config.yml")
            paths << config if File.exist?(config)
            current = File.dirname(current)
          end

          # Add home directory config
          home_config = File.join(Dir.home, ".ace", "taskflow", "config.yml")
          paths << home_config if File.exist?(home_config)

          # Reverse to apply from home to current (cascade)
          paths.reverse
        end

        def self.load_file(path)
          content = YAML.load_file(path)
          return {} unless content.is_a?(Hash)

          # Extract taskflow section if present
          if content["taskflow"]
            extract_taskflow_config(content["taskflow"])
          else
            {}
          end
        rescue StandardError
          {}
        end

        def self.extract_taskflow_config(taskflow_section)
          config = {}

          # Map configuration structure
          config["root"] = taskflow_section["root"] if taskflow_section["root"]
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

          config
        end

        def self.deep_merge(hash1, hash2)
          result = hash1.dup

          hash2.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = deep_merge(result[key], value)
            else
              result[key] = value
            end
          end

          result
        end
      end
    end
  end
end