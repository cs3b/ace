# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../review"
# Commands
require_relative "commands/review"
require_relative "commands/synthesize"
require_relative "commands/list_presets"
require_relative "commands/list_prompts"

module Ace
  module Review
    # dry-cli based CLI registry for ace-review
    #
    # This replaces the Thor-based CLI with dry-cli while maintaining
    # complete command parity and user-facing behavior.
    module CLI
      extend Dry::CLI::Registry

      # Application commands registered in this CLI (single source of truth)
      REGISTERED_COMMANDS = %w[review synthesize list-presets list-prompts].freeze

      # dry-cli built-in commands (standard across all CLI gems)
      BUILTIN_COMMANDS = %w[version help --help -h --version].freeze

      # Auto-derived from REGISTERED + BUILTIN (no manual maintenance needed)
      # Using Set for O(1) lookup performance
      KNOWN_COMMANDS = Set.new(REGISTERED_COMMANDS + BUILTIN_COMMANDS).freeze

      # Default command to use when first argument is not a known command
      DEFAULT_COMMAND = "review"

      # Separator for array options that won't conflict with internal commas
      # ASCII Unit Separator (0x1F) is designed for separating fields
      ARRAY_SEPARATOR = "\x1F"

      # Start the CLI with default command routing
      #
      # This method handles the default task routing that was previously
      # in the exe/ace-review wrapper. Moving it here makes the routing
      # logic testable and ensures consistent behavior for all consumers
      # (shell, tests, internal Ruby calls).
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      #
      # @example From shell
      #   Ace::Review::CLI.start(ARGV)
      #
      # @example From tests
      #   result = Ace::Review::CLI.start(["--preset", "code-pr"])
      def self.start(args)
        # Pre-process args to handle dry-cli's array option accumulation limitation
        # dry-cli only returns the last occurrence of --subject/--model flags,
        # but Thor accumulated all. We merge multiple occurrences into comma-separated
        # values, which the existing ReviewCommand already handles correctly.
        args = preprocess_array_options(args)

        # If args is empty OR first argument isn't a known command,
        # prepend the default command. This maintains Thor's default_task parity.
        if args.empty? || !known_command?(args.first)
          args = [DEFAULT_COMMAND] + args
        end

        Dry::CLI.new(self).call(arguments: args)
      end

      # Pre-process array options to work around dry-cli limitation
      #
      # dry-cli's type: :array only captures the last occurrence of a flag.
      # Thor accumulated all occurrences. This method merges multiple
      # occurrences using ARRAY_SEPARATOR (not comma) to preserve internal commas
      # in subject values like "files:a.rb,b.rb".
      #
      # @param args [Array<String>] Raw command-line arguments
      # @return [Array<String>] Pre-processed arguments with merged array options
      def self.preprocess_array_options(args)
        result = []
        i = 0
        accumulated_subject = []
        accumulated_model = []

        while i < args.length
          arg = args[i]

          # Track --subject occurrences for merging
          if arg == "--subject" || arg.start_with?("--subject=")
            value = extract_flag_value(arg, args, i)
            accumulated_subject << value
            i = skip_to_next_arg(args, i)
            next
          end

          # Track --model occurrences for merging
          if arg == "--model" || arg.start_with?("--model=")
            value = extract_flag_value(arg, args, i)
            accumulated_model << value
            i = skip_to_next_arg(args, i)
            next
          end

          result << arg
          i += 1
        end

        # Insert merged flags after the command name (if present) but before other args.
        # If first element is a known command, preserve it at position 0.
        # Use ARRAY_SEPARATOR to preserve internal commas in values.
        insert_pos = result.first && known_command?(result.first) ? 1 : 0
        result.insert(insert_pos, "--model", accumulated_model.join(",")) unless accumulated_model.empty?
        # Subject uses ARRAY_SEPARATOR to preserve internal commas (e.g., files:a.rb,b.rb)
        result.insert(insert_pos, "--subject", accumulated_subject.join(ARRAY_SEPARATOR)) unless accumulated_subject.empty?

        result
      end

      # Extract value from flag argument
      #
      # @param arg [String] Current argument (may be --flag=value or just --flag)
      # @param args [Array<String>] All arguments
      # @param index [Integer] Current index
      # @return [String] Extracted value
      def self.extract_flag_value(arg, args, index)
        if arg.include?('=')
          arg.split('=', 2)[1]
        elsif index + 1 < args.length && !args[index + 1].start_with?('--')
          args[index + 1]
        else
          ""
        end
      end

      # Calculate next index after consuming flag value
      #
      # @param args [Array<String>] All arguments
      # @param index [Integer] Current index
      # @return [Integer] Next index to process
      def self.skip_to_next_arg(args, index)
        if args[index].include?('=') || (index + 1 < args.length && !args[index + 1].start_with?('--'))
          index + 2
        else
          index + 1
        end
      end

      # Check if argument is a known command
      #
      # @param arg [String] First argument to check
      # @return [Boolean] true if it's a command, false if it's an argument
      def self.known_command?(arg)
        return false if arg.nil?

        KNOWN_COMMANDS.include?(arg)
      end

      # Register the review command (default)
      register "review", Commands::Review.new

      # Register the synthesize command
      register "synthesize", Commands::Synthesize.new

      # Register the list-presets command
      register "list-presets", Commands::ListPresets.new

      # Register the list-prompts command
      register "list-prompts", Commands::ListPrompts.new

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-review",
        version: Ace::Review::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd
    end
  end
end
