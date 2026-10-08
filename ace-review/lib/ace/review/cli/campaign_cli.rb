# frozen_string_literal: true
require_relative "commands/campaign/start"
require_relative "commands/campaign/status"
require_relative "commands/campaign/record_round"
require_relative "commands/campaign/finish"
require_relative "commands/campaign/resume"
require_relative "commands/campaign/assess"

module Ace
  module Review
    module CLI
      module CampaignCLI
        extend Ace::Support::Cli::RegistryDsl
        PROGRAM_NAME = "ace-review campaign"
        REGISTERED_COMMANDS = [["start", "Start/reuse a frozen campaign"], ["status", "Inspect history and evidence"],
          ["record-round", "Pin or record scoped evidence"], ["finish", "Validate current acceptance"], ["resume", "Authorize a finite next phase"], ["assess", "Record verified finding assessment"]].freeze
        HELP_EXAMPLES = ["ace-review campaign start --subject subject.json --contract requirements.md --profile delivery",
          "ace-review campaign status ID --format json", "ace-review campaign record-round ID --input round.json",
          "ace-review campaign finish ID --format json"].freeze
        register "start", Commands::Campaign::Start
        register "status", Commands::Campaign::Status
        register "record-round", Commands::Campaign::RecordRound
        register "finish", Commands::Campaign::Finish
        register "resume", Commands::Campaign::Resume
        register "assess", Commands::Campaign::Assess
        help = Ace::Support::Cli::HelpCommand.build(program_name: PROGRAM_NAME, version: Ace::Review::VERSION,
          commands: [["start", "Start/reuse a frozen campaign"], ["status", "Inspect history and evidence"],
            ["record-round", "Pin or record scoped evidence"], ["finish", "Validate current acceptance"], ["resume", "Authorize a finite next phase"], ["assess", "Record verified finding assessment"]],
          examples: ["ace-review campaign start --subject subject.json --contract requirements.md --profile delivery",
            "ace-review campaign status ID --format json", "ace-review campaign record-round ID --input round.json",
            "ace-review campaign finish ID --format json"])
        register "help", help
        register "--help", help
        register "-h", help
      end
    end
  end
end
