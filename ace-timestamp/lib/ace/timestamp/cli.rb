# frozen_string_literal: true

require "ace/core/cli/base"
require_relative "commands/encode_command"
require_relative "commands/decode_command"
require_relative "commands/config_command"
require_relative "version"

module Ace
  module Timestamp
    # CLI interface for ace-timestamp using Thor
    #
    # @example Encode a timestamp
    #   $ ace-timestamp encode "2025-01-06 12:30:00"
    #   i50jj3
    #
    # @example Decode a compact ID
    #   $ ace-timestamp decode i50jj3
    #   2025-01-06 12:30:00 UTC
    #
    # @example Show configuration
    #   $ ace-timestamp config
    #   year_zero: 2000
    #   alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
    #
    class CLI < Ace::Core::CLI::Base
      # Override help to add examples section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Format Details:"
        shell.say "  Compact ID: 6-character Base36 string (e.g., 'i50jj3')"
        shell.say "  Coverage: 108 years from year_zero (default: 2000-2107)"
        shell.say "  Precision: ~1.85 seconds"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-timestamp encode '2025-01-06 12:30:00'   # Encode to compact ID"
        shell.say "  ace-timestamp encode now                     # Encode current time"
        shell.say "  ace-timestamp decode i50jj3                  # Decode to timestamp"
        shell.say "  ace-timestamp config --verbose               # Show full config"
      end

      desc "encode [TIMESTAMP]", "Encode a timestamp to a 6-character compact ID"
      long_desc <<~DESC
        Encode a timestamp to a 6-character Base36 compact ID.

        TIMESTAMP can be:
        - ISO format: '2025-01-06T12:30:00Z'
        - Readable: '2025-01-06 12:30:00'
        - Old format: '20250106-123000'
        - 'now' or empty: current time

        EXAMPLES:

          $ ace-timestamp encode '2025-01-06 12:30:00'
          i50jj3

          $ ace-timestamp encode now
          (current time as compact ID)

          $ ace-timestamp encode --year-zero 2025 '2025-01-06'
          (compact ID with 2025 as base year)
      DESC
      method_option :year_zero, type: :numeric, aliases: "-y", desc: "Base year for encoding (default: 2000)"
      def encode(timestamp = nil)
        Commands::EncodeCommand.execute(timestamp, options.transform_keys(&:to_sym))
      end

      desc "decode COMPACT_ID", "Decode a compact ID to a timestamp"
      long_desc <<~DESC
        Decode a 6-character Base36 compact ID to a timestamp.

        OUTPUT FORMATS:
        - readable (default): '2025-01-06 12:30:00 UTC'
        - iso: '2025-01-06T12:30:00Z'
        - timestamp: '20250106-123000'

        EXAMPLES:

          $ ace-timestamp decode i50jj3
          2025-01-06 12:30:00 UTC

          $ ace-timestamp decode i50jj3 --format iso
          2025-01-06T12:30:00Z

          $ ace-timestamp decode i50jj3 --format timestamp
          20250106-123000
      DESC
      method_option :year_zero, type: :numeric, aliases: "-y", desc: "Base year for decoding (default: 2000)"
      method_option :format, type: :string, aliases: "-f", desc: "Output format (readable, iso, timestamp)"
      def decode(compact_id)
        Commands::DecodeCommand.execute(compact_id, options.transform_keys(&:to_sym))
      end

      desc "config", "Show current configuration"
      long_desc <<~DESC
        Display the current ace-timestamp configuration.

        Shows year_zero and alphabet settings from the configuration cascade.
        Use --verbose to see additional details about configuration sources
        and ID format specifications.

        EXAMPLES:

          $ ace-timestamp config
          year_zero: 2000
          alphabet: 0123456789abcdefghijklmnopqrstuvwxyz

          $ ace-timestamp config --verbose
          (full config with sources and format details)
      DESC
      def config
        Commands::ConfigCommand.execute(options.transform_keys(&:to_sym))
      end

      # Define version command
      version_command "ace-timestamp", Ace::Timestamp::VERSION

      # Default command is help
      default_task :help
    end
  end
end
