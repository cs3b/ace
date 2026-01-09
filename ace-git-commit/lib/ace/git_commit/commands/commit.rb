# frozen_string_literal: true

module Ace
  module GitCommit
    module Commands
      # dry-cli Command class for the commit command
      #
      # This command generates and executes git commits with LLM-generated
      # or user-provided messages, maintaining complete parity with the
      # Thor implementation.
      class Commit < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Generate and execute git commit

          Generate a commit message using LLM or use a provided message,
          then stage files and commit.

          When no files are specified, all changes are staged.
          When files are provided, only those files are staged and committed.

          Default Command Routing:
            Unknown arguments are auto-routed to 'commit' - files can be passed directly:
              ace-git-commit file.rb                   → ace-git-commit commit file.rb
              ace-git-commit lib/ test/               → ace-git-commit commit lib/ test/
            No need to type 'commit' explicitly

          Configuration:
            Global config:  ~/.ace/git/config.yml
            Project config: .ace/git-commit/config.yml
        DESC

        example [
          "ace-git-commit                    # Commit all changes",
          "ace-git-commit src/auth.rb        # Commit specific file",
          "ace-git-commit -i 'fix bug'       # With intention",
          "ace-git-commit -m 'feat: add'     # With explicit message",
          "ace-git-commit --only-staged      # Only staged changes"
        ]

        # Define files as variadic argument (can be 0 or more)
        argument :files, required: false, type: :array, desc: "Files to commit"

        # Commit options
        option :intention, type: :string, aliases: %w[-i], desc: "Provide context for LLM message generation"
        option :message, type: :string, aliases: %w[-m], desc: "Use provided message directly (no LLM)"
        option :model, type: :string, desc: "Override default LLM model (e.g., glite, gflash)"
        option :only_staged, type: :boolean, aliases: %w[-s], desc: "Commit only currently staged changes"
        option :dry_run, type: :boolean, aliases: %w[-n], desc: "Show what would be committed without doing it"
        option :force, type: :boolean, aliases: %w[-f], desc: "Force operation (for future use)"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary and informational messages"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output (default: true)"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Extract files array from options (dry-cli passes args as :files)
          @files = Array(options[:files] || [])

          # Remove dry-cli specific keys (args is leftover arguments)
          @options = options.reject { |k, _| k == :files || k == :args }

          execute
        end

        private

        def execute
          display_config_summary

          orchestrator = Organisms::CommitOrchestrator.new
          success = orchestrator.execute(commit_options)

          success ? 0 : 1
        rescue GitError => e
          $stderr.puts "Error: #{e.message}"
          1
        rescue Interrupt
          $stderr.puts "\nCommit cancelled"
          130
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
            only_staged: @options[:only_staged] || false,
            dry_run: @options[:dry_run] || false,
            debug: @options[:debug] || false,
            force: @options[:force] || false,
            verbose: @options[:verbose] != false,  # Default true
            quiet: @options[:quiet] || false
          )
        end

        def load_effective_config
          gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)

          resolver = Ace::Config.create(
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
