# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../git"
require_relative "cli/commands/diff"
require_relative "cli/commands/status"
require_relative "cli/commands/branch"
require_relative "cli/commands/pr"
require_relative "cli/commands/service_merge"

module Ace
  module Git
    # ace-support-cli command registry for ace-git.
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # Mirrors the exe's normalized_args logic so in-process tests
      # can exercise range-pattern routing.
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: normalized_args(args))
      end

      # Normalize arguments to handle empty args and git range patterns.
      # Extracted from exe/ace-git for in-process testability.
      def self.normalized_args(argv)
        return ["--help"] if argv.empty?
        return ["diff"] + argv if git_range_pattern?(argv.first)

        argv
      end

      def self.git_range_pattern?(arg)
        return false if arg.nil?

        return true if arg.match?(/\.\.\.?/) # Range operators: .. or ...
        return true if arg.match?(/[~^]\d*/) # Ref modifiers: ~, ~2, ^, ^2
        return true if arg == "HEAD"         # Exact HEAD match
        return true if arg.match?(/@\{/)     # Reflog: @{1}, @{yesterday}

        false
      end

      private_class_method :git_range_pattern?

      PROGRAM_NAME = "ace-git"

      REGISTERED_COMMANDS = [
        ["diff", "Show filtered git diff output"],
        ["status", "Show repository status and PR context"],
        ["branch", "Show current branch information"],
        ["pr", "Forge-neutral pull request lifecycle: show, create, update, ready, merge"],
        ["service merge", "Fixed receiver-owned exact-head merge envelope"],
        ["service create", "Fixed receiver-owned draft PR creation"],
        ["service update", "Fixed receiver-owned draft PR update"],
        ["service ready", "Fixed receiver-owned reviewed PR readiness"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-git diff --since 7d           # Changes from last week",
        "ace-git diff -p 'lib/**' -f summary  # Filtered summary",
        "ace-git status --no-pr            # Quick status, skip network",
        "ace-git pr show 25 --format json  # Normalized PR evidence"
      ].freeze

      register "diff", Commands::Diff.new
      register "status", Commands::Status.new
      register "branch", Commands::Branch.new
      register "pr show", Commands::Pr::Show.new
      register "pr create", Commands::Pr::Create.new
      register "pr update", Commands::Pr::Update.new
      register "pr ready", Commands::Pr::Ready.new
      register "pr merge", Commands::Pr::Merge.new
      register "service merge", Commands::ServiceMerge.new
      %w[create update ready].each do |operation|
        register "service #{operation}", Commands::ServiceMerge.new(operation: operation)
      end

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-git",
        version: Ace::Git::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Git::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
