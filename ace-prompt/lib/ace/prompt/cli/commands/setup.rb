# frozen_string_literal: true

require_relative "../../organisms/prompt_initializer"

module Ace
  module Prompt
    module CLI
      module Commands
      # dry-cli Command class for the setup command
      #
      # This wraps the existing PromptInitializer logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Setup < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Create prompt workspace and initialize with template

          By default:
            - Creates {project_root}/.cache/ace-prompt/prompts/ directory
            - Archives existing the-prompt.md if present
            - Copies template to the-prompt.md
            - Uses tmpl://the-prompt-base template
        DESC

        example [
          'ace-prompt setup              # Basic setup (archives existing prompt)',
          '--template bug                # Custom template (short form)',
          '--template tmpl://custom      # Custom template (full URI)',
          '--no-archive                  # Skip archiving existing prompt',
          '--force                       # Force overwrite (alias for --no-archive)',
          '--task 121                    # Setup for specific task'
        ]

        option :template, type: :string, aliases: %w[-t],
                          desc: "Template name or URI (e.g., 'bug' or 'tmpl://the-prompt-bug')"
        option :no_archive, type: :boolean,
                            desc: "Skip archiving existing prompt file"
        option :force, type: :boolean, aliases: %w[-f],
                       desc: "Skip archiving (alias for --no-archive)"
        option :task, type: :string,
                      desc: "Use task's prompts directory (e.g., '117' or '121.01')"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

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
            return exit_failure("Setup failed: #{result[:error]}")
          end

          $stdout.puts "Prompt initialized:"
          $stdout.puts "  Path: #{result[:path]}"
          if result[:archive_path]
            $stdout.puts "  Archive: #{result[:archive_path]}"
          end
          exit_success
        rescue StandardError => e
          exit_failure("Setup failed: #{e.message}")
        end

        private

        # Resolve task prompt path from explicit task ID or auto-detection
        # This is the global task resolution used by ALL commands
        #
        # @param task_option [String, nil] Explicit task ID from --task flag
        # @return [String, nil] Path to the-prompt.md in task's prompts directory, or nil for default
        def resolve_task_prompt_path(task_option)
          require_relative "../../atoms/task_path_resolver"
          require "ace/git"

          # If task ID is explicitly provided, use it
          if task_option
            result = Atoms::TaskPathResolver.resolve(task_option)
            raise Error, result[:error] unless result[:found]

            prompts_dir = result[:prompts_path]
            FileUtils.mkdir_p(prompts_dir)
            return File.join(prompts_dir, "the-prompt.md")
          end

          # Check if auto-detection is enabled in config
          return nil unless Ace::Prompt.config.dig("task", "detection")

          # Try to extract task ID from current branch (via ace-git for I/O)
          branch = Ace::Git::Molecules::BranchReader.current_branch
          return nil unless branch

          extracted_task_id = Atoms::TaskPathResolver.extract_from_branch(branch)
          return nil unless extracted_task_id

          # Resolve task path
          result = Atoms::TaskPathResolver.resolve(extracted_task_id)
          return nil unless result[:found]

          prompts_dir = result[:prompts_path]
          FileUtils.mkdir_p(prompts_dir)
          File.join(prompts_dir, "the-prompt.md")
        rescue StandardError => e
          # For explicit --task, re-raise the error
          raise if task_option

          # For auto-detection, notify user and continue without task context
          warn "[ace-prompt] Task auto-detection skipped: #{e.message}"
          nil
        end
      end
    end
  end
end
end
