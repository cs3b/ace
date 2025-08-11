# frozen_string_literal: true

require "dry/cli"
require_relative "../../../../integrations/claude_commands_installer"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        module Claude
          class Integrate < Dry::CLI::Command
            desc "Install Claude Code commands to .claude/ directory"

            option :dry_run, type: :boolean, default: false,
              desc: "Show what would be installed without modifying files"
            option :verbose, type: :boolean, default: false,
              desc: "Show detailed installation information"
            option :backup, type: :boolean, default: false,
              desc: "Backup existing installation"
            option :force, type: :boolean, default: false,
              desc: "Overwrite existing files"
            option :source, type: :string,
              desc: "Custom source directory"

            def call(**options)
              # Use refactored installer with CLI options
              installer = CodingAgentTools::Integrations::ClaudeCommandsInstaller.new(
                nil, # Use default project root detection
                dry_run: options[:dry_run] || false,
                verbose: options[:verbose] || false,
                backup: options[:backup] || false,
                force: options[:force] || false,
                source: options[:source]
              )
              result = installer.run
              exit(result.exit_code) if result.exit_code != 0
            end
          end
        end
      end
    end
  end
end
