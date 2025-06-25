# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # FileOperationConfirmer handles interactive confirmation prompts for file operations
    # It automatically detects CI environments and adjusts behavior accordingly
    class FileOperationConfirmer
      # Confirmation result
      ConfirmationResult = Struct.new(:confirmed?, :reason, :auto_decision?) do
        def denied?
          !confirmed?
        end
      end

      attr_reader :security_logger

      # Initialize the file operation confirmer
      # @param security_logger [SecurityLogger, nil] Logger for security events
      # @param input [IO] Input stream for prompts (defaults to STDIN)
      # @param output [IO] Output stream for prompts (defaults to STDOUT)
      def initialize(security_logger: nil, input: $stdin, output: $stdout)
        @security_logger = security_logger || create_default_logger
        @input = input
        @output = output
      end

      # Confirm a file overwrite operation
      # @param file_path [String] Path to the file that would be overwritten
      # @param force [Boolean] Whether to force the operation without prompting
      # @return [ConfirmationResult] Result of the confirmation
      def confirm_overwrite(file_path, force: false)
        # If force is enabled, auto-confirm
        if force
          @security_logger.log_event(:overwrite_confirmed,
            path: file_path,
            metadata: {forced: true, reason: "Force flag provided"})
          return ConfirmationResult.new(true, "Force flag provided", true)
        end

        # Check if file exists
        unless File.exist?(file_path)
          return ConfirmationResult.new(true, "File does not exist", true)
        end

        # In non-interactive environments, deny by default for safety
        unless interactive_environment?
          @security_logger.log_event(:overwrite_denied,
            path: file_path,
            metadata: {reason: "Non-interactive environment", auto_decision: true})
          return ConfirmationResult.new(false, "Non-interactive environment (use --force to override)", true)
        end

        # Interactive confirmation
        result = prompt_user_confirmation(file_path)

        if result.confirmed?
          @security_logger.log_event(:overwrite_confirmed,
            path: file_path,
            metadata: {interactive: true, reason: result.reason})
        else
          @security_logger.log_event(:overwrite_denied,
            path: file_path,
            metadata: {interactive: true, reason: result.reason})
        end

        result
      end

      # Check if we're in an interactive environment
      # @return [Boolean] True if environment supports interactive prompts
      def interactive_environment?
        # Check if we're in a TTY
        return false unless @input.tty? && @output.tty?

        # Check for common CI environment indicators
        ci_indicators = [
          "CI",
          "CONTINUOUS_INTEGRATION",
          "GITHUB_ACTIONS",
          "GITLAB_CI",
          "TRAVIS",
          "CIRCLECI",
          "JENKINS_URL",
          "BUILDKITE",
          "DRONE"
        ]

        # If any CI indicator is set, we're likely in CI
        ci_detected = ci_indicators.any? { |var| ENV[var] }

        # Return true only if we have TTY and no CI detected
        !ci_detected
      end

      private

      # Create default security logger
      # @return [SecurityLogger] Default logger instance
      def create_default_logger
        require_relative "../atoms/security_logger"
        Atoms::SecurityLogger.new
      end

      # Prompt the user for confirmation
      # @param file_path [String] Path to the file
      # @return [ConfirmationResult] User's decision
      def prompt_user_confirmation(file_path)
        @output.print "File '#{File.basename(file_path)}' already exists. Overwrite? [y/N]: "
        @output.flush

        begin
          # Set a timeout for the prompt to avoid hanging in edge cases
          response = nil
          timeout_duration = 30 # seconds

          if defined?(Timeout)
            Timeout.timeout(timeout_duration) do
              response = @input.gets&.strip&.downcase
            end
          else
            response = @input.gets&.strip&.downcase
          end

          case response
          when "y", "yes"
            ConfirmationResult.new(true, "User confirmed", false)
          when "n", "no", "", nil
            ConfirmationResult.new(false, "User declined", false)
          else
            # Invalid response, treat as decline for safety
            ConfirmationResult.new(false, "Invalid response (treated as decline)", false)
          end
        rescue => e
          # If anything goes wrong with the prompt, err on the side of caution
          @security_logger.log_error(e, context: {operation: "user_prompt", file_path: file_path})
          ConfirmationResult.new(false, "Prompt error (#{e.class.name})", true)
        end
      end
    end
  end
end
