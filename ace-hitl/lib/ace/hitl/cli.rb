# frozen_string_literal: true

require "ace/support/cli"
require_relative "../hitl/version"
require_relative "cli/commands/create"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/update"
require_relative "cli/commands/wait"

module Ace
  module Hitl
    module HitlCLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-hitl"

      REGISTERED_COMMANDS = [
        ["create", "Create HITL event"],
        ["show", "Show HITL event details"],
        ["list", "List HITL events"],
        ["update", "Update HITL event metadata or answer"],
        ["wait", "Wait for an answer on a specific HITL event"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-hitl list --status pending",
        "ace-hitl show abc123 --content",
        "ace-hitl create \"Which auth strategy?\" --kind decision",
        "ace-hitl update abc123 --answer \"Use JWT with refresh tokens\"",
        "ace-hitl wait abc123 --poll-every 600 --timeout 14400"
      ].freeze

      register "create", CLI::Commands::Create
      register "show", CLI::Commands::Show
      register "list", CLI::Commands::List
      register "update", CLI::Commands::Update
      register "wait", CLI::Commands::Wait

      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-hitl",
        version: Ace::Hitl::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Hitl::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd

      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end
    end
  end
end
