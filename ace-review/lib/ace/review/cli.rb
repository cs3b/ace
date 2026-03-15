# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../review"
# Commands
require_relative "cli/commands/review"

module Ace
  module Review
    # CLI namespace for ace-review command loading.
    #
    # ace-review uses a single-command ace-support-cli entrypoint that calls
    # CLI::Commands::Review directly from the executable.
    module CLI
      # Separator for array options that won't conflict with internal commas
      # ASCII Unit Separator (0x1F) is designed for separating fields
      ARRAY_SEPARATOR = "\x1F"

      # Pre-process array options to work around ace-support-cli limitation
      #
      # ace-support-cli's type: :array only captures the last occurrence of a flag.
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

        # Insert merged flags at position 0 (single-command mode, no command name to skip)
        result.insert(0, "--model", accumulated_model.join(",")) unless accumulated_model.empty?
        # Subject uses ARRAY_SEPARATOR to preserve internal commas (e.g., files:a.rb,b.rb)
        result.insert(0, "--subject", accumulated_subject.join(ARRAY_SEPARATOR)) unless accumulated_subject.empty?

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

      # Entry point for CLI invocation (used by tests via cli_helpers)
      #
      # @param args [Array<String>] Command-line arguments
      def self.start(args)
        Ace::Support::Cli::Runner.new(Commands::Review).call(args: args)
      end
    end
  end
end
