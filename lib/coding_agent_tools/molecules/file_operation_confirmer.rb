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
            metadata: { forced: true, reason: 'Force flag provided' })
          return ConfirmationResult.new(true, 'Force flag provided', true)
        end

        # Check if file exists
        return ConfirmationResult.new(true, 'File does not exist', true) unless File.exist?(file_path)

        # In non-interactive environments, deny by default for safety
        unless interactive_environment?
          @security_logger.log_event(:overwrite_denied,
            path: file_path,
            metadata: { reason: 'Non-interactive environment', auto_decision: true })
          return ConfirmationResult.new(false, 'Non-interactive environment (use --force to override)', true)
        end

        # Interactive confirmation
        result = prompt_user_confirmation(file_path)

        if result.confirmed?
          @security_logger.log_event(:overwrite_confirmed,
            path: file_path,
            metadata: { interactive: true, reason: result.reason })
        else
          @security_logger.log_event(:overwrite_denied,
            path: file_path,
            metadata: { interactive: true, reason: result.reason })
        end

        result
      end

      # Check if we're in an interactive environment
      # @return [Boolean] True if environment supports interactive prompts
      def interactive_environment?
        # Allow environment override for development scenarios
        # This is useful for AI coding environments like Claude Code
        if ENV['CODING_AGENT_TOOLS_FORCE_INTERACTIVE']
          debug_log('Environment override: FORCE_INTERACTIVE enabled')
          return ENV['CODING_AGENT_TOOLS_FORCE_INTERACTIVE'] == 'true'
        end

        # Check for common CI environment indicators first
        ci_indicators = [
          'CI',
          'CONTINUOUS_INTEGRATION',
          'GITHUB_ACTIONS',
          'GITLAB_CI',
          'TRAVIS',
          'CIRCLECI',
          'JENKINS_URL',
          'BUILDKITE',
          'DRONE'
        ]

        # If any CI indicator is set, we're definitely in CI
        ci_detected = ci_indicators.any? { |var| ENV[var] }
        if ci_detected
          debug_log('CI environment detected, treating as non-interactive')
          return false
        end

        # Check if we're in a TTY
        has_tty = @input.tty? && @output.tty?

        # For development environments that might not have proper TTY
        # but are still interactive (like Claude Code), be more permissive
        if !has_tty
          # Check for known development environment indicators
          if ENV['TERM'] || ENV['CLAUDE_CODE'] || ENV['VSCODE_PID']
            debug_log('Development environment detected without TTY, treating as interactive')
            return true
          end

          debug_log('No TTY and no development environment indicators, treating as non-interactive')
          return false
        end

        debug_log('TTY detected and no CI environment, treating as interactive')
        true
      end

      private

      # Create default security logger
      # @return [SecurityLogger] Default logger instance
      def create_default_logger
        require_relative '../atoms/security_logger'
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
          when 'y', 'yes'
            ConfirmationResult.new(true, 'User confirmed', false)
          when 'n', 'no', '', nil
            ConfirmationResult.new(false, 'User declined', false)
          else
            # Invalid response, treat as decline for safety
            ConfirmationResult.new(false, 'Invalid response (treated as decline)', false)
          end
        rescue => e
          # If anything goes wrong with the prompt, err on the side of caution
          @security_logger.log_error(e, context: { operation: 'user_prompt', file_path: file_path })
          ConfirmationResult.new(false, "Prompt error (#{e.class.name})", true)
        end
      end

      # Debug logging helper
      # @param message [String] Debug message to log
      def debug_log(message)
        # Only log if debug environment variable is set
        puts "Debug: #{message}" if ENV['CODING_AGENT_TOOLS_DEBUG']
      end
    end
  end
end
