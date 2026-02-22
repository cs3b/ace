# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../version"
require_relative "../molecules/task_loader"
require_relative "../molecules/release_resolver"

# Reuse existing command classes
require_relative "commands/idea"
require_relative "commands/ideas"
require_relative "commands/idea/create"
require_relative "commands/idea/done"
require_relative "commands/idea/park"
require_relative "commands/idea/unpark"
require_relative "commands/idea/reschedule"

module Ace
  module Taskflow
    # Flat CLI registry for ace-idea (idea management).
    #
    # Replaces the nested `ace-taskflow idea <subcommand>` pattern with
    # flat `ace-idea <command>` invocations.
    module IdeaCLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-idea"

      REGISTERED_COMMANDS = %w[list create done park unpark reschedule].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "list"

      HELP_EXAMPLES = [
        ["List pending ideas", "ace-idea"],
        ["Capture a new idea", "ace-idea create \"Add dark mode support\""],
        ["Mark idea as done", "ace-idea done my-feature"],
        ["Park an idea for later", "ace-idea park low-priority-item"],
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Ideas
      register "show", CLI::Commands::Idea
      register "create", CLI::Commands::IdeaSubcommands::Create
      register "done", CLI::Commands::IdeaSubcommands::Done
      register "park", CLI::Commands::IdeaSubcommands::Park
      register "unpark", CLI::Commands::IdeaSubcommands::Unpark
      register "reschedule", CLI::Commands::IdeaSubcommands::Reschedule

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-idea",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Clear caches before each invocation
      def self.start(args)
        Ace::Taskflow::Molecules::TaskLoader.clear_cache!
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
        super
      end
    end
  end
end
