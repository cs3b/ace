# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../docs"
# CLI Commands
require_relative "cli/status_command"
require_relative "cli/discover_command"
require_relative "cli/update_command"
require_relative "cli/analyze_command"
require_relative "cli/validate_command"
require_relative "cli/analyze_consistency_command"

module Ace
  module Docs
    # dry-cli based CLI registry for ace-docs
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        Dry::CLI.new(self).call(arguments: args)
      end

      # Register all commands
      register "status", StatusCommand.new
      register "discover", DiscoverCommand.new
      register "update", UpdateCommand.new
      register "analyze", AnalyzeCommand.new
      register "validate", ValidateCommand.new
      register "analyze-consistency", AnalyzeConsistencyCommand.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-docs",
        version: Ace::Docs::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
