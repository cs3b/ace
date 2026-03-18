# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require "ace/support/fs"
require "fileutils"
# Atoms (needed for CLI helpers)
require_relative "atoms/task_path_resolver"
require_relative "atoms/defaults"
require "ace/git"
# Commands
require_relative "cli/commands/process"
require_relative "cli/commands/setup"
# Organisms (needed for command logic)
require_relative "organisms/prompt_processor"
require_relative "organisms/prompt_initializer"

module Ace
  module PromptPrep
    # ace-support-cli based CLI registry for ace-prompt-prep
    #
    # This follows the Hanami pattern with all commands in CLI::Commands:: namespace.
    module CLI
      extend Ace::Core::CLI::RegistryDsl

      PROGRAM_NAME = "ace-prompt-prep"

      REGISTERED_COMMANDS = [
        ["process", "Process prompts from workspace"],
        ["setup", "Setup prompt prep environment"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-prompt-prep process --task 148    # Process prompts for task",
        "ace-prompt-prep setup                 # Initialize workspace"
      ].freeze

      # Register the process command
      register "process", Commands::Process.new

      # Register the setup command
      register "setup", Commands::Setup.new

      # Register version command
      version_cmd = Ace::Core::CLI::VersionCommand.build(
        gem_name: "ace-prompt-prep",
        version: Ace::PromptPrep::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::PromptPrep::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd

      # Shared helper module for common CLI functionality
      module Helpers
        # Resolve task prompt path from explicit task ID or auto-detection
        # This is the global task resolution used by ALL commands
        #
        # @param task_option [String, nil] Explicit task ID from --task flag
        # @return [String, nil] Path to the-prompt.md in task's prompts directory, or nil for default
        def self.resolve_task_prompt_path(task_option)

          # If task ID is explicitly provided, use it
          if task_option
            result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve(task_option)
            raise Error, result[:error] unless result[:found]

            prompts_dir = result[:prompts_path]
            FileUtils.mkdir_p(prompts_dir)
            return File.join(prompts_dir, "the-prompt.md")
          end

          # Check if auto-detection is enabled in config
          return nil unless Ace::PromptPrep.config.dig("task", "detection")

          # Try to extract task ID from current branch (via ace-git for I/O)
          branch = Ace::Git::Molecules::BranchReader.current_branch
          return nil unless branch

          extracted_task_id = Ace::PromptPrep::Atoms::TaskPathResolver.extract_from_branch(branch)
          return nil unless extracted_task_id

          # Resolve task path
          result = Ace::PromptPrep::Atoms::TaskPathResolver.resolve(extracted_task_id)
          return nil unless result[:found]

          prompts_dir = result[:prompts_path]
          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          unless path_within_root?(prompts_dir, project_root)
            warn "[ace-prompt-prep] Task auto-detection skipped: resolved path outside project root"
            return nil
          end

          FileUtils.mkdir_p(prompts_dir)
          File.join(prompts_dir, "the-prompt.md")
        rescue StandardError => e
          # For explicit --task, re-raise the error
          raise if task_option

          # For auto-detection, notify user and continue without task context
          warn "[ace-prompt-prep] Task auto-detection skipped: #{e.message}"
          nil
        end

        # Returns true when path is inside root (or equal to root)
        #
        # @param path [String]
        # @param root [String]
        # @return [Boolean]
        def self.path_within_root?(path, root)
          expanded_path = File.expand_path(path)
          expanded_root = File.expand_path(root)
          expanded_path == expanded_root || expanded_path.start_with?("#{expanded_root}/")
        end
      end
    end
  end
end
