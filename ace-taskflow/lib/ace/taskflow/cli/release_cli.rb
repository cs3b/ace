# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../version"
require_relative "../molecules/release_resolver"

# Reuse existing command classes
require_relative "commands/release"
require_relative "commands/releases"

module Ace
  module Taskflow
    # Flat CLI registry for ace-release (release management).
    #
    # Replaces the nested `ace-taskflow release/releases` pattern with
    # flat `ace-release <command>` invocations.
    module ReleaseCLI
      extend Dry::CLI::Registry
      extend Ace::Core::CLI::DryCli::DefaultRouting

      PROGRAM_NAME = "ace-release"

      REGISTERED_COMMANDS = %w[list show].freeze

      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      DEFAULT_COMMAND = "list"

      HELP_EXAMPLES = [
        ["List all releases", "ace-release"],
        ["Show current release details", "ace-release show"],
        ["Show a specific release", "ace-release show v.1.0.0"],
      ].freeze

      # Register flat commands (reusing existing command classes)
      register "list", CLI::Commands::Releases
      register "show", CLI::Commands::Release

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-release",
        version: Ace::Taskflow::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Clear caches before each invocation
      def self.start(args)
        Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!
        super
      end
    end
  end
end
