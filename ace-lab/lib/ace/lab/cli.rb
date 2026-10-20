# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../lab"
require_relative "cli/commands/projects"
require_relative "cli/commands/agents"
require_relative "cli/commands/services"
require_relative "cli/commands/resolve"
require_relative "cli/commands/route"
require_relative "cli/commands/status"
require_relative "cli/commands/prepare"
require_relative "cli/commands/project_add"
require_relative "cli/commands/install"
require_relative "cli/commands/verify"

module Ace
  module Lab
    # ace-support-cli based CLI registry for ace-lab
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-lab"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["projects", "List lab projects visible to the verified caller"],
        ["agents", "List lab agents in a project by stable ID"],
        ["services", "List lab services in a project by stable ID"],
        ["resolve", "Resolve one lab entry by exact stable ID"],
        ["route", "Select a configured capable service in a project"],
        ["status", "Show lab configuration and local file state (read-only)"],
        ["prepare", "Prepare accounts, directories, permissions, keys and roles from the trusted install manifest"],
        ["project add", "Register a project and make it ready for team work (repository, _overseer, lab config)"],
        ["install", "Perform the full new-lab installation from the trusted install manifest"],
        ["verify", "Verify the installed lab's readiness under the target accounts (read-only)"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-lab projects --format json",
        "ace-lab agents --project atlas --format json",
        "ace-lab resolve --id atlas-planner --format json",
        "ace-lab route --project atlas --capability search --format json",
        "ace-lab status --format json",
        "ace-lab prepare --dry-run",
        "ace-lab project add atlas --path /Users/ace/lab/atlas --remote git@forge:atlas/atlas.git",
        "ace-lab install --dry-run",
        "ace-lab verify --format json"
      ].freeze

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end

      # Register application commands
      register "projects", CLI::Commands::Projects.new
      register "agents", CLI::Commands::Agents.new
      register "services", CLI::Commands::Services.new
      register "resolve", CLI::Commands::Resolve.new
      register "route", CLI::Commands::Route.new
      register "status", CLI::Commands::Status.new
      register "prepare", CLI::Commands::Prepare.new
      register "project add", CLI::Commands::ProjectAdd.new
      register "install", CLI::Commands::Install.new
      register "verify", CLI::Commands::Verify.new

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
