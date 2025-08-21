# frozen_string_literal: true

require "yaml"
require "pathname"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Code
      # Manages loading and resolving review presets from configuration file
      class ReviewPresetManager
        DEFAULT_CONFIG_PATH = ".coding-agent/code-review.yml"
        
        attr_reader :config_path, :config, :project_root

        def initialize(config_path: nil, project_root: nil)
          @project_root = project_root || CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          @config_path = resolve_config_path(config_path)
          @config = load_configuration
        end

        # Load a specific preset by name
        def load_preset(preset_name)
          return nil unless config && config["presets"]
          
          preset = config["presets"][preset_name]
          return nil unless preset
          
          # Merge with defaults if they exist
          defaults = config["defaults"] || {}
          merge_with_defaults(preset, defaults)
        end

        # Get list of available preset names
        def available_presets
          return [] unless config && config["presets"]
          config["presets"].keys.sort
        end

        # Check if a preset exists
        def preset_exists?(preset_name)
          available_presets.include?(preset_name)
        end

        # Get the default model from configuration
        def default_model
          config&.dig("defaults", "model")
        end

        # Get the default context from configuration
        def default_context
          config&.dig("defaults", "context")
        end

        # Get the default output format
        def default_output_format
          config&.dig("defaults", "output_format") || "markdown"
        end

        # Resolve a preset configuration into actionable components
        def resolve_preset(preset_name, overrides = {})
          preset = load_preset(preset_name)
          return nil unless preset

          resolved = {
            description: preset["description"],
            system_prompt: resolve_system_prompt(preset["system_prompt"], overrides[:system_prompt]),
            context: resolve_context_config(preset["context"], overrides[:context]),
            subject: resolve_subject_config(preset["subject"], overrides[:subject]),
            model: overrides[:model] || preset["model"] || default_model,
            output_format: overrides[:output_format] || preset["output_format"] || default_output_format
          }

          resolved
        end

        private

        def resolve_config_path(custom_path)
          if custom_path
            Pathname.new(custom_path).absolute? ? custom_path : File.join(project_root, custom_path)
          else
            File.join(project_root, DEFAULT_CONFIG_PATH)
          end
        end

        def load_configuration
          return nil unless File.exist?(config_path)
          
          begin
            YAML.load_file(config_path)
          rescue => e
            warn "Warning: Failed to load code review configuration from #{config_path}: #{e.message}"
            nil
          end
        end

        def merge_with_defaults(preset, defaults)
          merged = preset.dup
          
          # Only merge in defaults that aren't already set in the preset
          defaults.each do |key, value|
            merged[key] ||= value unless key == "context" && preset["context"].nil?
          end
          
          merged
        end

        def resolve_system_prompt(preset_prompt, override_prompt)
          return override_prompt if override_prompt
          return nil unless preset_prompt
          
          # If it's a path, resolve it relative to project root
          if preset_prompt.include?("/") || preset_prompt.end_with?(".md")
            prompt_path = File.join(project_root, preset_prompt)
            return prompt_path if File.exist?(prompt_path)
            
            # Try without project root prefix (might be absolute)
            return preset_prompt if File.exist?(preset_prompt)
          end
          
          preset_prompt
        end

        def resolve_context_config(preset_context, override_context)
          return parse_context_yaml(override_context) if override_context
          return nil if preset_context.nil?
          
          # If it's a string, it's a preset name for the context tool
          return preset_context if preset_context.is_a?(String)
          
          # Otherwise it should be a hash with files/commands
          preset_context
        end

        def resolve_subject_config(preset_subject, override_subject)
          # Handle git range shorthand (e.g., "HEAD~1..HEAD")
          if override_subject && override_subject.is_a?(String) && looks_like_git_range?(override_subject)
            return { "commands" => ["git diff #{override_subject}"] }
          end
          
          return parse_context_yaml(override_subject) if override_subject
          preset_subject
        end

        def parse_context_yaml(input)
          return input unless input.is_a?(String)
          
          # Try to parse as YAML if it looks like YAML
          if input.include?(":") || input.start_with?("-")
            begin
              YAML.safe_load(input)
            rescue
              input
            end
          else
            input
          end
        end

        def looks_like_git_range?(str)
          # Common git range patterns
          str.match?(/^[A-Z@~^]+(\.\.|\.\.\.)[A-Z@~^]+$/i) ||
          str.match?(/^[a-f0-9]{6,}(\.\.|\.\.\.)[a-f0-9]{6,}$/i) ||
          str.match?(/^(HEAD|main|master|develop)(~\d+)?(\.\.|\.\.\.)/i)
        end
      end
    end
  end
end