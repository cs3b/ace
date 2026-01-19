# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
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
    # dry-cli based CLI registry for ace-prompt-prep
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[process setup].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "process"

      # Register the process command (default)
      register "process", Commands::Process.new

      # Register the setup command
      register "setup", Commands::Setup.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-prompt-prep",
        version: Ace::PromptPrep::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

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
          FileUtils.mkdir_p(prompts_dir)
          File.join(prompts_dir, "the-prompt.md")
        rescue StandardError => e
          # For explicit --task, re-raise the error
          raise if task_option

          # For auto-detection, notify user and continue without task context
          warn "[ace-prompt-prep] Task auto-detection skipped: #{e.message}"
          nil
        end
      end
    end
  end
end
