# frozen_string_literal: true

require_relative "../../organisms/prompt_initializer"

module Ace
  module PromptPrep
    module CLI
      module Commands
        # ace-support-cli Command class for the setup command
        #
        # This wraps the existing PromptInitializer logic in a ace-support-cli compatible
        # interface, maintaining complete parity with the Thor implementation.
        class Setup < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Create prompt workspace and initialize with template

            By default:
              - Creates {project_root}/.ace-local/prompt-prep/prompts/ directory
              - Archives existing the-prompt.md if present
              - Copies template to the-prompt.md
              - Uses tmpl://the-prompt-base template
          DESC

          example [
            "                             # Basic setup (archives existing prompt)",
            "--template bug               # Custom template (short form)",
            "--template tmpl://custom     # Custom template (full URI)",
            "--no-archive                 # Skip archiving existing prompt",
            "--force                      # Force overwrite (alias for --no-archive)",
            "--task 121                   # Setup for specific task"
          ]

          option :template, type: :string, aliases: %w[-t],
            desc: "Template name or URI (e.g., 'bug' or 'tmpl://the-prompt-bug')"
          option :no_archive, type: :boolean,
            desc: "Skip archiving existing prompt file"
          option :force, type: :boolean, aliases: %w[-f],
            desc: "Skip archiving (alias for --no-archive)"
          option :task, type: :string,
            desc: "Use task's prompts directory (e.g., '117' or '121.01')"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            template_uri = options[:template] || Organisms::PromptInitializer::DEFAULT_TEMPLATE_URI
            force = options[:force] || options[:no_archive] || false

            # Resolve task prompt path (handles both explicit --task and auto-detection)
            task_prompt_path = resolve_task_prompt_path(options[:task])
            # Extract target directory from resolved path
            target_dir = task_prompt_path ? File.dirname(task_prompt_path) : nil

            result = Organisms::PromptInitializer.setup(
              template_uri: template_uri,
              force: force,
              target_dir: target_dir
            )

            unless result[:success]
              raise Ace::Support::Cli::Error.new("Setup failed: #{result[:error]}")
            end

            $stdout.puts "Prompt initialized:"
            $stdout.puts "  Path: #{result[:path]}"
            if result[:archive_path]
              $stdout.puts "  Archive: #{result[:archive_path]}"
            end
          rescue => e
            raise Ace::Support::Cli::Error.new("Setup failed: #{e.message}")
          end

          private

          # Resolve task prompt path using shared helper
          def resolve_task_prompt_path(task_option)
            Ace::PromptPrep::CLI::Helpers.resolve_task_prompt_path(task_option)
          end
        end
      end
    end
  end
end
