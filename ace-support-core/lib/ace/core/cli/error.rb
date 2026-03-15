# frozen_string_literal: true

module Ace
  module Core
    module CLI
      # Exception raised to signal non-zero exit code from CLI commands.
      #
      # This exception is used in the exception-based exit code pattern
      # defined in ADR-023. Commands raise this error on failure, and
      # the exe wrapper catches it and exits with the specified code.
      #
      # @example Raising from a command
      #   def call(file:, **options)
      #     raise Error.new("file required") if file.nil?
      #
      #     result = do_work(file)
      #
      #     if result[:success]
      #       puts result[:message]
      #       # Success - no exception, exits 0
      #     else
      #       raise Error.new(result[:error])
      #     end
      #   end
      #
      # @example Catching in exe wrapper
      #   # exe/ace-gem
      #   begin
      #     Ace::Gem::CLI.start(ARGV)
      #   rescue Ace::Core::CLI::Error => e
      #     warn e.message
      #     exit(e.exit_code)
      #   end
      #
          # @see ADR-023 CLI framework conventions
      class Error < StandardError
        # Exit code to return when this exception is caught
        # @return [Integer]
        attr_reader :exit_code

        # Original error message without prefix
        # @return [String]
        attr_reader :original_message

        # Initialize a new CLI error
        #
        # @param message [String] Error message to display
        # @param exit_code [Integer] Exit code (default: 1)
        def initialize(message, exit_code: 1)
          @original_message = message
          super(message)
          @exit_code = exit_code
        end

        # Return the original message without prefix.
        # This ensures .message returns what was passed to the constructor.
        # @return [String] Original message
        def message
          @original_message
        end

        # Prepend "Error: " to message for consistent user-facing output.
        # exe wrappers use warn e.to_s which calls this method.
        # @return [String] Message with "Error: " prefix
        def to_s
          "Error: #{@original_message}"
        end
      end
    end
  end
end
