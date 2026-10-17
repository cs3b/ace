# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../lab"
require_relative "cli/commands/projects"
require_relative "cli/commands/agents"
require_relative "cli/commands/services"
require_relative "cli/commands/resolve"
require_relative "cli/commands/route"
require_relative "cli/commands/service"
require_relative "cli/commands/assignment"
require_relative "cli/commands/command_execute"
require_relative "cli/commands/run"

module Ace
  module Lab
    # ace-support-cli based CLI registry for ace-lab
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-lab"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["run", "Run one explicitly authorized project command"],
        ["run-status", "Inspect an original command execution without running it"],
        ["projects", "List lab projects visible to the verified caller"],
        ["agents", "List lab agents in a project by stable ID"],
        ["services", "List lab services in a project by stable ID"],
        ["resolve", "Resolve one lab entry by exact stable ID"],
        ["route", "Select a configured capable service in a project"],
        ["service request", "Request one authorized service operation"],
        ["service status", "Read a service request outcome"],
        ["service listen", "Serve the ordinary fixed merge receiver on its configured socket"],
        ["assignment prepare", "Retain reviewed task input for ordinary Assign registration"],
        ["assignment drive", "Drive one original execution through the installed ordinary owner"],
        ["assignment request", "Send one retained operation to the installed ordinary Assign owner"],
        ["assignment campaign", "Drive one canonical campaign review round through the installed ordinary owner"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-lab projects --format json",
        "ace-lab agents --project atlas --format json",
        "ace-lab resolve --id atlas-planner --format json",
        "ace-lab route --project atlas --capability search --format json"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        return CLI::Commands::Run.invoke(args.drop(1)) if args.first == "run" && !(args.take(args.index("--") || args.size).include?("--help") || args.take(args.index("--") || args.size).include?("-h"))
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register application commands
      register "projects", CLI::Commands::Projects.new
      register "agents", CLI::Commands::Agents.new
      register "services", CLI::Commands::Services.new
      register "resolve", CLI::Commands::Resolve.new
      register "route", CLI::Commands::Route.new
      register "service request", CLI::Commands::Service::Request.new
      register "service status", CLI::Commands::Service::Status.new
      register "service listen", CLI::Commands::Service::Listen.new
      register "run", CLI::Commands::Run.new
      register "run-status", CLI::Commands::RunStatus.new
      register "command execute", CLI::Commands::CommandExecute.new
      register "assignment prepare", CLI::Commands::Assignment::Prepare.new
      register "assignment campaign", CLI::Commands::Assignment::Campaign.new
      register "assignment drive", CLI::Commands::Assignment::Drive.new
      register "assignment request", CLI::Commands::Assignment::Request.new

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-lab",
        version: Ace::Lab::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Lab::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
