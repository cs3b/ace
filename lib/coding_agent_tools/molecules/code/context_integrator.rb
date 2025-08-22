# frozen_string_literal: true

require "tempfile"
require "yaml"
require_relative "../../organisms/system/command_executor"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Code
      # Handles dual context tool calls for review command
      class ContextIntegrator
        attr_reader :executor, :project_root

        def initialize
          @executor = CodingAgentTools::Organisms::System::CommandExecutor.new
          @project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
        end

        # Generate context (background information) using context tool
        def generate_context(context_config)
          return "" if context_config.nil? || context_config == "none"

          # If it's a string, treat it as a preset name
          if context_config.is_a?(String)
            execute_context_command("--preset", context_config)
          elsif context_config.is_a?(Hash)
            # Check for presets key for multi-preset support
            if context_config["presets"] || context_config[:presets]
              presets = context_config["presets"] || context_config[:presets]
              validate_preset_names(presets)
              preset_names = Array(presets).join(",")
              
              # Load preset content
              preset_content = execute_context_command("--preset", preset_names)
              
              # If there are additional files/commands, load them too
              additional_config = context_config.dup
              additional_config.delete("presets")
              additional_config.delete(:presets)
              
              if additional_config.any?
                yaml_content = YAML.dump(additional_config)
                additional_content = execute_context_command_with_yaml(yaml_content)
                # Merge both contents
                [preset_content, additional_content].compact.join("\n\n")
              else
                preset_content
              end
            else
              # Original behavior for non-preset configs
              yaml_content = YAML.dump(context_config)
              execute_context_command_with_yaml(yaml_content)
            end
          else
            ""
          end
        end

        # Generate subject (what to review) using context tool
        def generate_subject(subject_config)
          return "" if subject_config.nil?

          # Handle git range shorthand
          if subject_config.is_a?(String) && looks_like_git_range?(subject_config)
            subject_config = { "commands" => ["git diff #{subject_config}"] }
          end

          if subject_config.is_a?(String)
            # Treat as YAML content
            execute_context_command_with_yaml(subject_config)
          elsif subject_config.is_a?(Hash)
            # Convert hash to YAML and pass to context tool
            yaml_content = YAML.dump(subject_config)
            execute_context_command_with_yaml(yaml_content)
          else
            ""
          end
        end

        private

        def validate_preset_names(presets)
          Array(presets).each do |preset|
            unless preset.is_a?(String) && preset.match?(/^[a-z0-9\-_]+$/i)
              raise ArgumentError, "Invalid preset name: #{preset}"
            end
          end
        end

        def execute_context_command(*args)
          Tempfile.create(["context-output-", ".md"]) do |tmpfile|
            # Execute context command with output to temp file
            result = executor.execute("context", *args, "--output", tmpfile.path)
            
            if result.success?
              # Read the generated context from the temp file
              File.read(tmpfile.path)
            else
              raise "Context generation failed: #{result.stderr}"
            end
          end
        end

        def execute_context_command_with_yaml(yaml_content)
          # Create temporary YAML file for complex configurations
          Tempfile.create(["context-config-", ".yml"]) do |yaml_file|
            yaml_file.write(yaml_content)
            yaml_file.flush

            Tempfile.create(["context-output-", ".md"]) do |output_file|
              # Execute context command with YAML file
              result = executor.execute("context", yaml_file.path, "--output", output_file.path)
              
              if result.success?
                File.read(output_file.path)
              else
                # Try passing the YAML content directly as a string
                result = executor.execute("context", yaml_content, "--output", output_file.path)
                if result.success?
                  File.read(output_file.path)
                else
                  raise "Context generation failed: #{result.stderr}"
                end
              end
            end
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