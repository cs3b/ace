# frozen_string_literal: true

require "ace/support/cli"
require_relative "../hitl/version"
require_relative "cli/commands/create"
require_relative "cli/commands/ask"
require_relative "cli/commands/show"
require_relative "cli/commands/list"
require_relative "cli/commands/update"
require_relative "cli/commands/wait"
require_relative "cli/commands/deliver"
require_relative "cli/commands/consume"
require_relative "cli/commands/cancel"
require_relative "cli/commands/pending"
require_relative "cli/commands/states"
require_relative "cli/commands/duty"
require_relative "cli/commands/serve"
require_relative "cli/commands/overseer_send"
require_relative "cli/commands/overseer_pending"
require_relative "cli/commands/overseer_ack"

module Ace
  module Hitl
    module HitlCLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-hitl"

      REGISTERED_COMMANDS = [
        ["create", "Create HITL event"],
        ["ask", "Ask a human via HITL and forward the request to the Lab"],
        ["show", "Show HITL event details"],
        ["list", "List HITL events"],
        ["update", "Update HITL event metadata or answer"],
        ["wait", "Wait for an answer on a specific HITL event"],
        ["deliver", "Deliver an answer (stdin) to a pending HITL relay request"],
        ["consume", "Wait for and consume the answer of one own HITL relay request"],
        ["cancel", "Cancel one HITL relay request with an audited reason"],
        ["pending", "List answerable HITL relay requests (host-broker)"],
        ["states", "List public HITL lifecycle projections (host-broker)"],
        ["duty", "Project pending and escalated HITL requests (host-broker)"],
        ["overseer-send", "Queue a bounded, type-tagged Overseer response (stdin)"],
        ["overseer-pending", "List queued Overseer responses (host-broker)"],
        ["overseer-ack", "Acknowledge one relayed Overseer response"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-hitl list --status pending",
        "ace-hitl show abc123 --content",
        "ace-hitl create \"Which auth strategy?\" --kind decision",
        "ace-hitl ask \"Proceed with deploy?\" --work W685 --effect-arg /bin/false --effect-cwd /tmp",
        "ace-hitl update abc123 --answer \"Use JWT with refresh tokens\"",
        "ace-hitl wait abc123 --poll-every 600 --timeout 14400"
      ].freeze

      register "create", CLI::Commands::Create
      register "ask", CLI::Commands::Ask
      register "show", CLI::Commands::Show
      register "list", CLI::Commands::List
      register "update", CLI::Commands::Update
      register "wait", CLI::Commands::Wait
      register "deliver", CLI::Commands::Deliver
      register "consume", CLI::Commands::Consume
      register "cancel", CLI::Commands::Cancel
      register "pending", CLI::Commands::Pending
      register "states", CLI::Commands::States
      register "duty", CLI::Commands::Duty
      register "serve", CLI::Commands::Serve
      register "overseer-send", CLI::Commands::OverseerSend
      register "overseer-pending", CLI::Commands::OverseerPending
      register "overseer-ack", CLI::Commands::OverseerAck

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
