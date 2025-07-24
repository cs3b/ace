# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    class PathConfigLoader
      DEFAULT_CONFIG = {
        "project" => {
          "root" => "..",
          "name" => "tools-meta"
        },
        "repositories" => {
          "scan_order" => [
            {
              "name" => "tools-meta",
              "path" => ".",
              "priority" => 1,
              "description" => "Main coordination and scripts"
            }
          ]
        },
        "path_patterns" => {
          "task_new" => {
            "template" => "dev-taskflow/current/{release}/tasks/{release}+task.{id}-{slug}.md",
            "variables" => {
              "release" => "release-manager current",
              "id" => "task-manager generate-id",
              "slug" => "user_input"
            }
          }
        },
        "resolution" => {
          "fuzzy" => {
            "enabled" => true,
            "min_similarity" => 0.5,
            "max_suggestions" => 10,
            "use_fzf" => true,
            "fallback_enabled" => true
          },
          "file_preferences" => {
            "preferred_extensions" => [".md", ".rb", ".yml", ".yaml"],
            "important_directories" => ["bin"]
          }
        },
        "security" => {
          "enforce_sandbox" => true,
          "forbidden_patterns" => [
            "**/.git/**",              # Git internals (version control)
            "**/node_modules/**",      # NPM dependencies
            "**/coverage/**",          # Test coverage files
            "**/tmp/**",               # Temporary files
            "**/*.log",                # Log files
            "**/.DS_Store",            # macOS system files
            "**/Gemfile.lock",         # Ruby dependency lock files
            "**/package-lock.json",    # Node.js dependency lock files
            "**/.*",                   # All other dot files and dot directories
            ".*"                       # Top-level dot files
          ]
        },
        "integration" => {
          "tools" => {
            "fzf" => {
              "enabled" => true,
              "command" => "fzf",
              "options" => "--height 40% --reverse --border"
            }
          },
          "multi_repo" => {
            "scan_all_by_default" => true,
            "conflict_resolution" => "priority_order"
          }
        },
        "performance" => {
          "cache" => {
            "enabled" => true,
            "ttl" => 300,
            "max_entries" => 1000
          },
          "limits" => {
            "max_files_scan" => 10000,
            "max_scan_depth" => 10,
            "operation_timeout" => 30
          }
        },
        "scoped_autocorrect" => {
          "scope_mappings" => {},
          "scope_autocorrect" => {}
        }
      }.freeze

      def initialize(project_root = nil, config_path = nil)
        @project_root = project_root || detect_project_root
        @config_path = config_path || default_config_path
      end

      def load
        return DEFAULT_CONFIG unless config_exists?

        config = YAML.load_file(@config_path)
        validate_config!(config)
        merge_with_defaults(config)
      rescue Psych::SyntaxError => e
        raise Error, "Invalid YAML in path configuration: #{e.message}"
      rescue => e
        raise Error, "Failed to load path configuration: #{e.message}"
      end

      def config_exists?
        File.exist?(@config_path)
      end

      def default_config_path
        File.join(@project_root, ".coding-agent", "path.yml")
      end

      private

      def detect_project_root
        CodingAgentTools::Atoms::ProjectRootDetector.find_project_root(Dir.pwd)
      end

      def validate_config!(config)
        raise Error, "Configuration must be a Hash" unless config.is_a?(Hash)

        validate_section!(config, "project", Hash)
        validate_section!(config, "repositories", Hash)
        validate_section!(config, "path_patterns", Hash)
        validate_section!(config, "resolution", Hash)
        validate_section!(config, "security", Hash)
        validate_section!(config, "integration", Hash)
        validate_section!(config, "performance", Hash)
        validate_section!(config, "scoped_autocorrect", Hash)
      end

      def validate_section!(config, section_name, expected_type)
        return unless config.key?(section_name)

        unless config[section_name].is_a?(expected_type)
          raise Error, "#{section_name} must be a #{expected_type.name}"
        end
      end

      def merge_with_defaults(config)
        merged = deep_merge(DEFAULT_CONFIG, config)

        # Ensure scan_order maintains proper structure
        if config.dig("repositories", "scan_order")
          merged["repositories"]["scan_order"] = config["repositories"]["scan_order"]
        end

        merged
      end

      def deep_merge(hash1, hash2)
        result = hash1.dup

        hash2.each do |key, value|
          result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
            deep_merge(result[key], value)
          else
            value
          end
        end

        result
      end
    end
  end
end
