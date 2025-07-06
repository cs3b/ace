# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # BinstubGenerator - Molecule for generating shell binstub scripts
    #
    # Responsibilities:
    # - Generate shell binstub content following project patterns
    # - Handle different binstub types (shell, ruby)
    # - Create proper argument passing and directory context
    # - Follow shell binstub patterns from dev-handbook
    class BinstubGenerator
      # Generates shell binstub content for a given alias configuration
      #
      # @param alias_name [String] Name of the binstub
      # @param alias_config [Hash] Configuration for the alias
      # @return [String] Shell script content
      def self.generate_shell_binstub(alias_name, alias_config)
        executable = alias_config["executable"]
        command = alias_config["command"]
        description = alias_config["description"]
        execution_context = alias_config["execution_context"] || "dev_tools"

        target_command = if command
          "./exe/#{executable} #{command}"
        else
          "./exe/#{executable}"
        end

        case execution_context
        when "project_root"
          generate_project_root_binstub(description, target_command)
        else
          generate_dev_tools_binstub(description, target_command)
        end
      end

      private

      # Generates binstub that runs from project root directory
      def self.generate_project_root_binstub(description, target_command)
        <<~SHELL_SCRIPT
          #!/bin/sh
          # #{description}

          set -e

          # Save original directory
          ORIGINAL_DIR="$(pwd)"

          # Trap to ensure we always return to original directory
          trap 'cd "$ORIGINAL_DIR"' EXIT

          # Change to project root directory where taskflow is accessible
          cd "$(dirname "$0")/.."

          echo "INFO: #{description} from project root directory: $(pwd)"

          # Execute the command from dev-tools subdirectory
          cd dev-tools && #{target_command} "$@"
        SHELL_SCRIPT
      end

      # Generates binstub that runs from dev-tools directory
      def self.generate_dev_tools_binstub(description, target_command)
        <<~SHELL_SCRIPT
          #!/bin/sh
          # #{description}

          set -e

          # Save original directory
          ORIGINAL_DIR="$(pwd)"

          # Trap to ensure we always return to original directory
          trap 'cd "$ORIGINAL_DIR"' EXIT

          # Change to dev-tools directory where the gem files are located
          cd "$(dirname "$0")/../dev-tools"

          echo "INFO: #{description} from dev-tools directory: $(pwd)"

          # Execute the main command with all arguments passed through
          #{target_command} "$@"
        SHELL_SCRIPT
      end

      # Generates all binstubs from a configuration hash
      #
      # @param config [Hash] Full binstub configuration
      # @return [Hash] Map of alias names to shell script content
      def self.generate_all_binstubs(config)
        aliases = config["aliases"] || {}
        binstubs = {}

        aliases.each do |alias_name, alias_config|
          case alias_config["type"]
          when "shell"
            binstubs[alias_name] = generate_shell_binstub(alias_name, alias_config)
          else
            raise CodingAgentTools::Error, "Unsupported binstub type: #{alias_config["type"]}"
          end
        end

        binstubs
      end
    end
  end
end
