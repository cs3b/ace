# frozen_string_literal: true

require "pathname"
require_relative "../../atoms/context/context_config_loader"

module CodingAgentTools
  module Molecules
    module Context
      # ContextPresetManager - Molecule for managing context preset configurations
      #
      # Responsibilities:
      # - Resolve preset configurations from config
      # - Handle path resolution for templates and outputs
      # - Provide preset listing and validation
      # - Apply security constraints to paths
      class ContextPresetManager
        def initialize(config_loader = nil, project_root = nil)
          @config_loader = config_loader || Atoms::Context::ContextConfigLoader.new(project_root)
          @project_root = project_root || @config_loader.project_root
          @config = nil
        end

        # Get list of available presets with descriptions
        #
        # @return [Array<Hash>] Array of preset info {name:, description:, template:, output:}
        def list_presets
          load_config_if_needed

          @config["presets"].map do |name, preset_config|
            {
              name: name,
              description: preset_config["description"] || "No description",
              template: resolve_template_path(preset_config["template"]),
              output: resolve_output_path(name, preset_config),
              chunk_limit: preset_config["chunk_limit"] || @config["settings"]["default_chunk_limit"]
            }
          end
        end

        # Resolve a preset configuration by name
        #
        # @param preset_name [String] Name of the preset
        # @return [Hash, nil] Resolved preset configuration or nil if not found
        def resolve_preset(preset_name)
          load_config_if_needed

          preset_config = @config["presets"][preset_name]
          return nil unless preset_config

          # Validate template file exists
          template_path = resolve_template_path(preset_config["template"])
          unless template_path && File.exist?(template_path)
            raise Error, "Template file not found for preset '#{preset_name}': #{preset_config["template"]}"
          end

          # Validate security constraints
          validate_template_path!(template_path)

          output_path = resolve_output_path(preset_name, preset_config)
          # Skip validation for stdout indicators
          if output_path && !is_stdout_indicator?(output_path)
            validate_output_path!(output_path)
          end

          {
            name: preset_name,
            description: preset_config["description"] || "No description",
            template: template_path,
            output: output_path,
            chunk_limit: preset_config["chunk_limit"] || @config["settings"]["default_chunk_limit"]
          }
        end

        # Check if a preset exists
        #
        # @param preset_name [String] Name of the preset
        # @return [Boolean] true if preset exists
        def preset_exists?(preset_name)
          load_config_if_needed
          @config["presets"].key?(preset_name)
        end

        # Get default output path for a preset
        #
        # @param preset_name [String] Name of the preset
        # @return [String] Default output path
        def default_output_path(preset_name)
          load_config_if_needed
          cache_dir = @config["settings"]["cache_directory"]
          File.join(@project_root, cache_dir, "#{preset_name}.md")
        end

        # Validate that all presets have valid configurations
        #
        # @return [Array<Hash>] Array of validation results
        def validate_all_presets
          load_config_if_needed

          @config["presets"].map do |name, preset_config|
            resolved = resolve_preset(name)
            {
              name: name,
              valid: true,
              template_exists: File.exist?(resolved[:template]),
              output_path: resolved[:output],
              message: "Valid"
            }
          rescue => e
            {
              name: name,
              valid: false,
              template_exists: false,
              output_path: nil,
              message: e.message
            }
          end
        end

        # Get configuration settings
        #
        # @return [Hash] Current configuration
        def get_config
          load_config_if_needed
          @config
        end

        private

        # Load configuration if not already loaded
        def load_config_if_needed
          @config ||= @config_loader.load
        end

        # Resolve template path relative to project root
        #
        # @param template_path [String] Template path from config
        # @return [String] Absolute template path
        def resolve_template_path(template_path)
          return nil unless template_path

          if Pathname.new(template_path).absolute?
            template_path
          else
            File.join(@project_root, template_path)
          end
        end

        # Resolve output path for a preset
        #
        # @param preset_name [String] Name of the preset
        # @param preset_config [Hash] Preset configuration
        # @return [String, nil] Resolved output path or stdout indicator
        def resolve_output_path(preset_name, preset_config)
          if preset_config["output"]
            # Use configured output path
            output_path = preset_config["output"]

            # Return stdout indicators as-is
            return output_path if is_stdout_indicator?(output_path)

            if Pathname.new(output_path).absolute?
              output_path
            else
              File.join(@project_root, output_path)
            end
          else
            # Return nil to indicate no output specified (will use stdout)
            nil
          end
        end

        # Check if a path indicates stdout output
        #
        # @param path [String] Path to check
        # @return [Boolean] true if path indicates stdout
        def is_stdout_indicator?(path)
          path && (path == "-" || path.downcase == "stdout")
        end

        # Validate template path against security constraints
        #
        # @param template_path [String] Template path to validate
        # @raise [Error] if path is not allowed
        def validate_template_path!(template_path)
          allowed_patterns = @config["security"]["allowed_template_paths"]
          forbidden_patterns = @config["security"]["forbidden_patterns"]

          begin
            relative_path = Pathname.new(template_path).relative_path_from(@project_root).to_s
          rescue ArgumentError
            # Handle absolute paths that can't be made relative
            relative_path = File.basename(template_path)
          end

          # Check against forbidden patterns first
          if path_matches_patterns?(relative_path, forbidden_patterns)
            raise Error, "Template path not allowed (forbidden pattern): #{relative_path}"
          end

          # Check against allowed patterns
          unless path_matches_patterns?(relative_path, allowed_patterns)
            raise Error, "Template path not allowed (not in allowed paths): #{relative_path}"
          end
        end

        # Validate output path against security constraints
        #
        # @param output_path [String] Output path to validate
        # @raise [Error] if path is not allowed
        def validate_output_path!(output_path)
          allowed_patterns = @config["security"]["allowed_output_paths"]
          forbidden_patterns = @config["security"]["forbidden_patterns"]

          begin
            relative_path = Pathname.new(output_path).relative_path_from(@project_root).to_s
          rescue ArgumentError
            # Handle absolute paths that can't be made relative
            relative_path = File.basename(output_path)
          end

          # Check against forbidden patterns
          if path_matches_patterns?(relative_path, forbidden_patterns)
            raise Error, "Output path not allowed (forbidden pattern): #{relative_path}"
          end

          # Check against allowed patterns
          unless path_matches_patterns?(relative_path, allowed_patterns)
            raise Error, "Output path not allowed (not in allowed paths): #{relative_path}"
          end
        end

        # Check if path matches any of the given patterns
        #
        # @param path [String] Path to check
        # @param patterns [Array<String>] Patterns to match against
        # @return [Boolean] true if path matches any pattern
        def path_matches_patterns?(path, patterns)
          patterns.any? do |pattern|
            if pattern.include?("*")
              # Glob pattern matching with support for ** (recursive)
              # Note: Don't use FNM_PATHNAME as it disables ** matching
              File.fnmatch(pattern, path)
            else
              # Prefix matching or exact matching
              path.start_with?(pattern) || path == pattern
            end
          end
        end
      end
    end
  end
end
