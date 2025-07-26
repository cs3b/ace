# frozen_string_literal: true

require "dry/cli"
require_relative "version"
require_relative "error"

module CodingAgentTools
  module Cli
    # Module to hold all CLI command definitions
    module Commands
      extend Dry::CLI::Registry

      # Simple command to display the gem version
      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts CodingAgentTools::VERSION
        end
      end

      # Registering the version command
      register "version", Version, aliases: ["v", "-v", "--version"]

      # Deferred command registration to avoid circular dependencies
      def self.register_llm_commands
        return if @llm_commands_registered

        require_relative "cli/commands/llm/models"
        require_relative "cli/commands/llm/query"
        require_relative "cli/commands/llm/usage_report"

        register "llm", aliases: [] do |prefix|
          prefix.register "models", Commands::LLM::Models
          prefix.register "query", Commands::LLM::Query
          prefix.register "usage_report", Commands::LLM::UsageReport
        end

        @llm_commands_registered = true
      end

      def self.register_task_commands
        return if @task_commands_registered

        require_relative "cli/commands/task/next"
        require_relative "cli/commands/task/recent"
        require_relative "cli/commands/task/all"
        require_relative "cli/commands/task/generate_id"

        register "task", aliases: [] do |prefix|
          prefix.register "next", Commands::Task::Next
          prefix.register "recent", Commands::Task::Recent
          prefix.register "all", Commands::Task::All
          prefix.register "generate-id", Commands::Task::GenerateId
        end

        @task_commands_registered = true
      end

      def self.register_release_commands
        return if @release_commands_registered

        require_relative "cli/commands/release/current"
        require_relative "cli/commands/release/next"
        require_relative "cli/commands/release/all"
        require_relative "cli/commands/release/generate_id"
        require_relative "cli/commands/release/validate"

        register "release", aliases: [] do |prefix|
          prefix.register "current", Commands::Release::Current
          prefix.register "next", Commands::Release::Next
          prefix.register "all", Commands::Release::All
          prefix.register "generate-id", Commands::Release::GenerateId
          prefix.register "validate", Commands::Release::Validate
        end

        @release_commands_registered = true
      end


      def self.register_dotfiles_commands
        return if @dotfiles_commands_registered

        require_relative "cli/commands/install_dotfiles"

        register "install-dotfiles", Commands::InstallDotfiles

        @dotfiles_commands_registered = true
      end

      def self.register_code_commands
        return if @code_commands_registered

        require_relative "cli/commands/code/review"
        require_relative "cli/commands/code/review_synthesize"
        require_relative "cli/commands/code/lint"

        register "code", aliases: [] do |prefix|
          prefix.register "review", Commands::Code::Review
          prefix.register "review-synthesize", Commands::Code::ReviewSynthesize
          prefix.register "lint", Commands::Code::Lint
        end

        @code_commands_registered = true
      end

      def self.register_code_lint_commands
        return if @code_lint_commands_registered

        require_relative "cli/commands/code_lint/all"
        require_relative "cli/commands/code_lint/ruby"
        require_relative "cli/commands/code_lint/markdown"
        require_relative "cli/commands/code_lint/docs_dependencies"

        register "code-lint", aliases: [] do |prefix|
          prefix.register "all", Commands::CodeLint::All
          prefix.register "ruby", Commands::CodeLint::Ruby
          prefix.register "markdown", Commands::CodeLint::Markdown
          prefix.register "docs-dependencies", Commands::CodeLint::DocsDependencies
        end

        @code_lint_commands_registered = true
      end

      def self.register_code_review_prepare_commands
        return if @code_review_prepare_commands_registered

        require_relative "cli/commands/code/review_prepare/session_dir"
        require_relative "cli/commands/code/review_prepare/project_context"
        require_relative "cli/commands/code/review_prepare/project_target"
        require_relative "cli/commands/code/review_prepare/prompt"

        register "code-review-prepare", aliases: [] do |prefix|
          prefix.register "session-dir", Commands::Code::ReviewPrepare::SessionDir
          prefix.register "project-context", Commands::Code::ReviewPrepare::ProjectContext
          prefix.register "project-target", Commands::Code::ReviewPrepare::ProjectTarget
          prefix.register "prompt", Commands::Code::ReviewPrepare::Prompt
        end

        @code_review_prepare_commands_registered = true
      end

      def self.register_nav_commands
        return if @nav_commands_registered

        require_relative "cli/commands/nav"
        require_relative "cli/commands/nav/path"
        require_relative "cli/commands/nav/tree"

        register "nav", aliases: [] do |prefix|
          prefix.register "path", Commands::Nav::Path
          prefix.register "tree", Commands::Nav::Tree
        end

        @nav_commands_registered = true
      end

      def self.register_handbook_commands
        return if @handbook_commands_registered

        require_relative "cli/commands/handbook/sync_templates"

        register "handbook", aliases: [] do |prefix|
          prefix.register "sync-templates", Commands::Handbook::SyncTemplates
        end

        @handbook_commands_registered = true
      end

      def self.register_reflection_commands
        return if @reflection_commands_registered

        require_relative "cli/commands/reflection/synthesize"

        register "reflection", aliases: [] do |prefix|
          prefix.register "synthesize", Commands::Reflection::Synthesize
        end

        @reflection_commands_registered = true
      end

      def self.register_git_commands
        return if @git_commands_registered

        require_relative "cli/commands/git/status"
        require_relative "cli/commands/git/commit"
        require_relative "cli/commands/git/add"
        require_relative "cli/commands/git/push"
        require_relative "cli/commands/git/pull"
        require_relative "cli/commands/git/log"
        require_relative "cli/commands/git/diff"
        require_relative "cli/commands/git/fetch"
        require_relative "cli/commands/git/checkout"
        require_relative "cli/commands/git/switch"
        require_relative "cli/commands/git/mv"
        require_relative "cli/commands/git/rm"
        require_relative "cli/commands/git/restore"

        register "git", aliases: [] do |prefix|
          prefix.register "status", Commands::Git::Status
          prefix.register "commit", Commands::Git::Commit
          prefix.register "add", Commands::Git::Add
          prefix.register "push", Commands::Git::Push
          prefix.register "pull", Commands::Git::Pull
          prefix.register "log", Commands::Git::Log
          prefix.register "diff", Commands::Git::Diff
          prefix.register "fetch", Commands::Git::Fetch
          prefix.register "checkout", Commands::Git::Checkout
          prefix.register "switch", Commands::Git::Switch
          prefix.register "mv", Commands::Git::Mv
          prefix.register "rm", Commands::Git::Rm
          prefix.register "restore", Commands::Git::Restore
        end

        @git_commands_registered = true
      end

      def self.register_all_commands
        return if @all_commands_registered

        require_relative "cli/commands/all"

        register "all", Commands::All

        @all_commands_registered = true
      end

      # Ensure commands are registered when CLI is used
      def self.call(*args)
        register_llm_commands
        register_task_commands
        register_release_commands
        register_dotfiles_commands
        register_code_commands
        register_code_lint_commands
        register_code_review_prepare_commands
        register_nav_commands
        register_handbook_commands
        register_reflection_commands
        register_git_commands
        register_all_commands
        super
      end
    end
  end
end
