# frozen_string_literal: true

require "dry/cli"
require "set"
require "ace/core"
require_relative "../review"
# Commands
require_relative "cli/commands/review"
require_relative "cli/commands/list_presets"
require_relative "cli/commands/list_prompts"

module Ace
  module Review
    # dry-cli based CLI registry for ace-review
    #
    # After the split, ace-review handles review execution and configuration.
    # Feedback management moved to ace-review-feedback.
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = "ace-review"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["review", "Run code review with preset or PR context"],
        ["list-presets", "List available review presets"],
        ["list-prompts", "List prompt modules for review"]
      ].freeze

      # Separator for array options that won't conflict with internal commas
      # ASCII Unit Separator (0x1F) is designed for separating fields
      ARRAY_SEPARATOR = "\x1F"

      # Known command names for preprocessing (derived from REGISTERED_COMMANDS)
      KNOWN_COMMAND_NAMES = REGISTERED_COMMANDS.map(&:first).to_set.freeze

      HELP_EXAMPLES = [
        "ace-review review --preset pr",
        "ace-review review --pr 90",
        "ace-review review --subject files:lib/app.rb",
        "ace-review list-presets",
        "ace-review list-prompts"
      ].freeze

      # Pre-process array options to work around dry-cli limitation
      #
      # dry-cli's type: :array only captures the last occurrence of a flag.
      # This method merges multiple occurrences using ARRAY_SEPARATOR
      # (not comma) to preserve internal commas in subject values
      # like "files:a.rb,b.rb".
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

        KNOWN_COMMAND_NAMES.include?(arg)
      end

      # Register the review command
      register "review", Commands::Review

      # Register the list-presets command
      register "list-presets", Commands::ListPresets

      # Register the list-prompts command
      register "list-prompts", Commands::ListPrompts

      # Register version command
      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: "ace-review",
        version: Ace::Review::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Review::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end
