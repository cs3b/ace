# frozen_string_literal: true

require "yaml"
require "pathname"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for loading and merging lint configuration
      class ConfigurationLoader
        DEFAULT_CONFIG = {
          "ruby" => {
            "enabled" => true,
            "linters" => {
              "standardrb" => { "enabled" => true, "autofix" => true },
              "security" => { "enabled" => true, "full_scan" => false },
              "cassettes" => { "enabled" => true, "threshold" => 51200 } # 50KB
            }
          },
          "markdown" => {
            "enabled" => true,
            "linters" => {
              "styleguide" => { "enabled" => true, "autofix" => true },
              "link_validation" => { "enabled" => true },
              "template_embedding" => { "enabled" => true },
              "task_metadata" => { "enabled" => true }
            },
            "order" => ["task_metadata", "link_validation", "template_embedding", "styleguide"]
          },
          "error_distribution" => {
            "enabled" => true,
            "max_files" => 4,
            "one_issue_per_file" => true
          }
        }.freeze

        attr_reader :config_path, :project_root

        def initialize(config_path: nil, project_root: nil)
          @config_path = find_config_path(config_path)
          @project_root = project_root || find_project_root
        end

        def load
          config = DEFAULT_CONFIG.dup
          
          if config_path && File.exist?(config_path)
            custom_config = load_yaml_file(config_path)
            config = deep_merge(config, custom_config) if custom_config
          end
          
          config
        end

        def validate
          return { valid: false, error: "Config file not found" } unless config_path
          
          begin
            config = load_yaml_file(config_path)
            validate_structure(config)
          rescue StandardError => e
            { valid: false, error: e.message }
          end
        end

        private

        def find_config_path(path)
          return path if path && File.exist?(path)
          
          # Look for .coding-agent/lint.yml in project root
          root = find_project_root
          default_path = File.join(root, ".coding-agent", "lint.yml")
          
          File.exist?(default_path) ? default_path : nil
        end

        def find_project_root
          # Look for common project markers
          markers = [".git", "Gemfile", "package.json", ".coding-agent"]
          
          current = Pathname.pwd
          until current.root?
            markers.each do |marker|
              return current.to_s if current.join(marker).exist?
            end
            current = current.parent
          end
          
          Dir.pwd
        end

        def load_yaml_file(path)
          YAML.load_file(path)
        rescue Psych::SyntaxError => e
          raise "Invalid YAML syntax: #{e.message}"
        end

        def deep_merge(hash1, hash2)
          hash1.merge(hash2) do |_key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge(old_val, new_val)
            else
              new_val
            end
          end
        end

        def validate_structure(config)
          errors = []
          
          # Validate top-level keys
          %w[ruby markdown].each do |lang|
            if config[lang] && !config[lang].is_a?(Hash)
              errors << "#{lang} must be a hash"
            end
          end
          
          # Validate linter configurations
          if config["ruby"] && config["ruby"]["linters"]
            validate_linters(config["ruby"]["linters"], "ruby", errors)
          end
          
          if config["markdown"] && config["markdown"]["linters"]
            validate_linters(config["markdown"]["linters"], "markdown", errors)
          end
          
          if errors.empty?
            { valid: true }
          else
            { valid: false, errors: errors }
          end
        end

        def validate_linters(linters, language, errors)
          unless linters.is_a?(Hash)
            errors << "#{language}.linters must be a hash"
            return
          end
          
          linters.each do |name, settings|
            unless settings.is_a?(Hash)
              errors << "#{language}.linters.#{name} must be a hash"
            end
          end
        end
      end
    end
  end
end