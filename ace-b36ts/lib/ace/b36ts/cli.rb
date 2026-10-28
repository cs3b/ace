# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "cli/commands/encode"
require_relative "cli/commands/decode"
require_relative "cli/commands/config"
require_relative "version"

module Ace
  module B36ts
    # CLI interface for ace-b36ts using ace-support-cli
    #
    # This follows the Hanami pattern with all commands in CLI::Commands:: namespace.
    #
    # @example Encode a timestamp
    #   $ ace-b36ts encode "2025-01-06 12:30:00"
    #   i50jj3
    #
    # @example Decode a compact ID
    #   $ ace-b36ts decode i50jj3
    #   2025-01-06 12:30:00 UTC
    #
    # @example Show configuration
    #   $ ace-b36ts config
    #   year_zero: 2000
    #   alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
    #
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-b36ts"

      REGISTERED_COMMANDS = [
        ["encode", "Encode timestamp to compact ID"],
        ["decode", "Decode compact ID to timestamp"],
        ["config", "Show current configuration"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-b36ts encode                          # Generate ID from now",
        "ace-b36ts encode 2024-01-15T10:30:00Z     # Encode specific time",
        "ace-b36ts decode abc123                   # Decode ID to timestamp"
      ].freeze

      # Register commands (Hanami pattern: CLI::Commands::*)
      register "encode", Commands::Encode
      register "decode", Commands::Decode
      register "config", Commands::Config

      # Spinel compiled builds dispatch through this table instead of the
      # runtime Registry: a class value that flows through a poly
      # Class|Instance|nil local misboxes class-attr reads (see pilot
      # REPORT.md). All table values are command CLASSES, which compile
      # and dispatch correctly. CRuby keeps using the registry.
      class SpinVersion < Ace::Support::Cli::Command
        desc "Show version information"

        def call(**_params)
          puts "ace-b36ts #{Ace::B36ts::VERSION}"
          0
        end
      end

      class SpinHelp < Ace::Support::Cli::Command
        desc "Show top-level help"
        argument :args, type: :array, required: false

        def call(**_params)
          cmd = Ace::Support::Cli::HelpCommand.build(
            program_name: PROGRAM_NAME,
            version: Ace::B36ts::VERSION,
            commands: REGISTERED_COMMANDS,
            examples: HELP_EXAMPLES
          )
          puts cmd.render
          0
        end
      end

      # Root `--help` page in the Usage renderer's exact format, rendered
      # from local constants (the generic Usage class needs runtime
      # const_defined?/respond_to? on the registry, which compiled builds
      # cannot dispatch). CRuby keeps using Help::Usage via Runner.
      class SpinUsage < Ace::Support::Cli::Command
        desc "Show usage"

        def call(**_params)
          parts = ["Usage: #{PROGRAM_NAME} [COMMAND]", "", "COMMANDS"]
          REGISTERED_COMMANDS.sort_by { |name, _desc| name }.each do |name, desc|
            parts << "  #{name}".ljust(34) + " # #{desc}"
          end
          parts << ""
          parts << "EXAMPLES"
          HELP_EXAMPLES.each { |entry| parts << "  #{entry}" }
          puts parts.join("\n")
          0
        end
      end

      SPINEL_COMMANDS = {
        "encode" => Commands::Encode,
        "decode" => Commands::Decode,
        "config" => Commands::Config,
        "version" => SpinVersion,
        "--version" => SpinVersion,
        "help" => SpinHelp,
        "--help" => SpinHelp,
        "-h" => SpinHelp
      }.freeze

      def self.spinel_command_for(name)
        case name
        when "encode" then Commands::Encode
        when "decode" then Commands::Decode
        when "config" then Commands::Config
        when "version", "--version" then SpinVersion
        when "help", "--help", "-h" then SpinHelp
        else
          raise Ace::Support::Cli::CommandNotFoundError, "Command not found: #{name}"
        end
      end

      # Version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-b36ts",
        version: Ace::B36ts::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::B36ts::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
