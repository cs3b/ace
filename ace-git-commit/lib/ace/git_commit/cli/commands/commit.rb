# frozen_string_literal: true

module Ace
  module GitCommit
    module CLI
      module Commands
        # ace-support-cli Command class for the commit command
        #
        # This command generates and executes git commits with LLM-generated
        # or user-provided messages, maintaining complete parity with the
        # Thor implementation.
        class Commit < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Generate and execute git commit

            Generate a commit message using LLM or use a provided message,
            then stage files and commit.

            When no files are specified, all changes are staged.
            When files are provided, only those files are staged and committed.

            Configuration:
              Global config:  ~/.ace/git/commit.yml
              Project config: .ace/git/commit.yml
              Package config: {package}/.ace/git/commit.yml
          DESC

          example [
            "                             # Commit all changes",
            "src/auth.rb                  # Commit specific file",
            "-i 'fix bug'                # With intention",
            "-m 'feat: add'              # With explicit message",
            "--only-staged                # Only staged changes",
            "--no-split                   # Force a single commit"
          ]

          # Define files as variadic argument (can be 0 or more)
          argument :files, required: false, type: :array, desc: "Files to commit"

          # Commit options
          option :intention, type: :string, aliases: %w[-i], desc: "Provide context for LLM message generation"
          option :message, type: :string, aliases: %w[-m], desc: "Use provided message directly (no LLM)"
          option :model, type: :string, desc: "Override default LLM model (e.g., glite, gflash)"
          option :only_staged, type: :boolean, aliases: %w[-s], desc: "Commit only currently staged changes"
          option :staged, type: :boolean, desc: "Alias for --only-staged"
          option :dry_run, type: :boolean, aliases: %w[-n], desc: "Show what would be committed without doing it"
          option :force, type: :boolean, aliases: %w[-f], desc: "Force operation (for future use)"
          option :no_split, type: :boolean, desc: "Force a single commit even when multiple config scopes are detected"

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :version, type: :boolean, desc: "Show version information"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            # Extract files array from options (ace-support-cli passes args as :files)
            @files = Array(options[:files] || [])

            # Remove ace-support-cli specific keys (args is leftover arguments)
            @options = options.reject { |k, _| k == :files || k == :args }
            if @options[:version]
              puts "ace-git-commit #{Ace::GitCommit::VERSION}"
              return 0
            end

            execute
          end

          private

          def execute
            display_config_summary

            orchestrator = Organisms::CommitOrchestrator.new
            success = orchestrator.execute(commit_options)

            raise Ace::Support::Cli::Error.new("Commit failed") unless success
          rescue GitError => e
            raise Ace::Support::Cli::Error.new(e.message)
          rescue Interrupt
            raise Ace::Support::Cli::Error.new("Commit cancelled", exit_code: 130)
          end

          def display_config_summary
            return if @options[:quiet]

            require "ace/core"
            Ace::Core::Atoms::ConfigSummary.display(
              command: "commit",
              config: load_effective_config,
              defaults: default_config,
              options: @options,
              quiet: false  # Don't suppress ConfigSummary itself
            )
          end

          def commit_options
            Models::CommitOptions.new(
              intention: @options[:intention],
              message: @options[:message],
              model: @options[:model],
              files: @files,
              only_staged: @options[:only_staged] || @options[:staged] || false,
              dry_run: @options[:dry_run] || false,
              debug: @options[:debug] || false,
              force: @options[:force] || false,
              verbose: @options[:verbose] != false,  # Default true
              quiet: @options[:quiet] || false,
              no_split: @options[:no_split] || false
            )
          end

          def load_effective_config
            gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
              File.expand_path("../../../../../..", __dir__)

            resolver = Ace::Support::Config.create(
              config_dir: ".ace",
              defaults_dir: ".ace-defaults",
              gem_path: gem_root
            )

            config = resolver.resolve_namespace("git", filename: "commit")
            config.data["git"] || config.data
          end

          def default_config
            gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
              File.expand_path("../../../../../..", __dir__)

            defaults_path = File.join(gem_root, ".ace-defaults", "git", "commit.yml")

            if File.exist?(defaults_path)
              require "yaml"
              YAML.safe_load_file(defaults_path, permitted_classes: [Symbol], aliases: true) || {}
            else
              {}
            end
          end
        end
      end
    end
  end
end
