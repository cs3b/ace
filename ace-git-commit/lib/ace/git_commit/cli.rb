# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module GitCommit
    class CLI < Ace::Core::CLI::Base
      default_task :commit

      # Override help to add usage examples and routing info
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Default Command Routing:"
        shell.say "  Unknown commands are auto-routed to 'commit' - files can be passed directly:"
        shell.say "    ace-git-commit file.rb                   → ace-git-commit commit file.rb"
        shell.say "    ace-git-commit lib/ test/               → ace-git-commit commit lib/ test/"
        shell.say "  No need to type 'commit' explicitly"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-git-commit                    # Commit all changes"
        shell.say "  ace-git-commit src/auth.rb        # Commit specific file"
        shell.say "  ace-git-commit -i 'fix bug'       # With intention"
        shell.say "  ace-git-commit -m 'feat: add'     # With explicit message"
        shell.say "  ace-git-commit --only-staged      # Only staged changes"
        shell.say ""
        shell.say "Configuration: ~/.ace/git-commit/config.yml"
        shell.say "Project config: .ace/git-commit/config.yml"
      end

      desc "commit [FILES...]", "Generate and execute git commit"
      long_desc <<~DESC
        Generate a commit message using LLM or use a provided message,
        then stage files and commit.

        When no files are specified, all changes are staged.
        When files are provided, only those files are staged and committed.
      DESC
      option :intention, type: :string, aliases: "-i", desc: "Provide context for LLM message generation"
      option :message, type: :string, aliases: "-m", desc: "Use provided message directly (no LLM)"
      option :model, type: :string, desc: "Override default LLM model (e.g., glite, gflash)"
      option :only_staged, type: :boolean, aliases: "-s", desc: "Commit only currently staged changes"
      option :dry_run, type: :boolean, aliases: "-n", desc: "Show what would be committed without doing it"
      option :debug, type: :boolean, aliases: "-d", desc: "Enable debug output"
      option :verbose, type: :boolean, desc: "Enable verbose output (default: true)"
      option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary and informational messages"
      option :force, type: :boolean, aliases: "-f", desc: "Force operation (for future use)"
      def commit(*files)
        # Handle --help/-h passed as first argument
        if files.first == "--help" || files.first == "-h"
          invoke :help, ["commit"]
          return 0
        end

        # Check if known Thor flags were passed as file arguments
        # This happens when using -v, --verbose, etc. without a command
        # Thor's default_task routes them to the default command as arguments
        known_thor_flags = %w[-v --verbose -q --quiet -d --debug --version -h --help]
        if files.any? { |f| known_thor_flags.include?(f) }
          # Known flag was passed as an argument
          # Show usage since flags should come before the command
          invoke :help, []
          return 0
        end

        require_relative "commands/commit_command"
        Commands::CommitCommand.new(files, options).execute
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-git-commit.

        EXAMPLES:

          $ ace-git-commit version
          $ ace-git-commit --version
      DESC
      def version
        puts "ace-git-commit #{VERSION}"
        0
      end
      map "--version" => :version

      # Handle unknown commands as arguments to the default 'commit' command
      def method_missing(command, *args)
        # Check if the "command" is a known Thor option flag
        # These should be handled by Thor's option parsing, not routed to commit
        known_thor_flags = %w[-v --verbose -q --quiet -d --debug --version -h --help]
        if known_thor_flags.include?(command.to_s)
          # Known flag was passed as a standalone argument
          # Show usage since no command was specified
          invoke :help, []
          return 0
        end

        invoke :commit, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end
