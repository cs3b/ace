# frozen_string_literal: true

require 'logger'
require 'pathname'

module CodingAgentTools
  module Atoms
    # SecurityLogger is an atom that provides security-focused logging
    # It sanitizes sensitive information from log messages to prevent
    # information disclosure while maintaining useful debugging info
    class SecurityLogger
      # Security event types
      EVENTS = {
        path_traversal_attempt: 'PATH_TRAVERSAL',
        invalid_path: 'INVALID_PATH',
        denied_access: 'DENIED_ACCESS',
        file_operation: 'FILE_OPERATION',
        overwrite_attempt: 'OVERWRITE_ATTEMPT',
        overwrite_denied: 'OVERWRITE_DENIED',
        overwrite_confirmed: 'OVERWRITE_CONFIRMED'
      }.freeze

      @@suppress_output = false

      attr_reader :logger

      # Suppress all security logger output (for testing)
      def self.suppress_output=(value)
        @@suppress_output = value
      end

      # Check if output is suppressed
      def self.suppress_output?
        @@suppress_output
      end

      # Initialize security logger
      # @param logger [Logger, nil] Logger instance (defaults to STDERR logger)
      def initialize(logger: nil)
        @logger = logger || create_default_logger
      end

      # Log a security event
      # @param event_type [Symbol] Type of security event (from EVENTS)
      # @param details [Hash] Event details (will be sanitized)
      # @option details [String] :path Path that triggered the event
      # @option details [String] :reason Reason for the security event
      # @option details [Hash] :metadata Additional metadata
      def log_event(event_type, details = {})
        return if self.class.suppress_output?

        event_name = EVENTS[event_type] || event_type.to_s.upcase
        sanitized = sanitize_details(details)

        message = build_message(event_name, sanitized)

        case event_type
        when :path_traversal_attempt, :denied_access
          logger.warn(message)
        when :invalid_path, :overwrite_denied
          logger.info(message)
        else
          logger.debug(message)
        end
      end

      # Log an error with sanitization
      # @param error [Exception] The error to log
      # @param context [Hash] Additional context (will be sanitized)
      def log_error(error, context = {})
        return if self.class.suppress_output?

        sanitized_context = sanitize_details(context)
        message = "[SECURITY_ERROR] #{error.class}: #{sanitize_message(error.message)}"
        message += " | Context: #{format_details(sanitized_context)}" unless sanitized_context.empty?

        logger.error(message)
      end

      private

      # Create default logger to STDERR
      # @return [Logger] Default logger instance
      def create_default_logger
        logger = Logger.new($stderr)
        logger.progname = 'CodingAgentTools::Security'
        logger.level = Logger::INFO
        logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime.iso8601}] #{severity} #{progname}: #{msg}\n"
        end
        logger
      end

      # Sanitize details to remove sensitive information
      # @param details [Hash] Details to sanitize
      # @return [Hash] Sanitized details
      def sanitize_details(details)
        sanitized = {}

        details.each do |key, value|
          sanitized[key] = case key
                           when :path
                             sanitize_path(value.to_s)
                           when :paths
                             value.map { |p| sanitize_path(p.to_s) }
                           when :reason, :message
                             sanitize_message(value.to_s)
                           when :metadata
                             value.is_a?(Hash) ? sanitize_details(value) : value.to_s
                           else
                             value.to_s
                           end
        end

        sanitized
      end

      # Sanitize a file path to hide sensitive information
      # @param path [String] Path to sanitize
      # @return [String] Sanitized path
      def sanitize_path(path)
        return '(empty)' if path.nil? || path.empty?

        # Check if it's a relative path first
        pathname = Pathname.new(path)

        # For relative paths that don't escape current directory, show as-is
        return path if pathname.relative? && !path.include?('..')

        # Detect path traversal attempts - if path contains .. sequences, treat as potential attack
        if path.include?('..')
          # Expand path to see where it leads
          begin
            expanded = File.expand_path(path)
          rescue StandardError
            return '[invalid-path]'
          end

          # For path traversal attempts, hide the path components
          components = Pathname.new(expanded).each_filename.to_a
          if components.length > 2
            return "[hidden]/#{components[-2..].join('/')}"
          elsif components.length > 0
            return "[hidden]/#{components.join('/')}"
          else
            return '[hidden]'
          end
        end

        # Expand path to handle relative components and get absolute form
        begin
          expanded = File.expand_path(path)
        rescue StandardError
          # If path expansion fails, sanitize conservatively
          return '[invalid-path]'
        end

        # Hide home directory details
        home = ENV['HOME']
        return expanded.sub(home, '~') if home && expanded.start_with?(home)

        # Hide absolute paths outside current directory
        pwd = Dir.pwd
        if expanded.start_with?('/') && !expanded.start_with?(pwd)
          # Show only the last two components for context
          components = Pathname.new(expanded).each_filename.to_a
          if components.length > 2
            return "[hidden]/#{components[-2..].join('/')}"
          elsif components.length > 0
            return "[hidden]/#{components.join('/')}"
          end
        end

        # For paths within current directory that were expanded, return original if relative
        return path if pathname.relative?

        # Otherwise return the expanded path
        expanded
      end

      # Sanitize a message to remove sensitive patterns
      # @param message [String] Message to sanitize
      # @return [String] Sanitized message
      def sanitize_message(message)
        # Remove potential sensitive patterns
        sanitized = message.dup

        # Hide potential API keys or tokens
        sanitized.gsub!(/\b[A-Za-z0-9_-]{20,}\b/, '[REDACTED]')

        # Hide email addresses
        sanitized.gsub!(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/, '[EMAIL]')

        # Hide IP addresses
        sanitized.gsub!(/\b(?:\d{1,3}\.){3}\d{1,3}\b/, '[IP]')

        sanitized
      end

      # Build log message from event and details
      # @param event_name [String] Name of the event
      # @param details [Hash] Sanitized event details
      # @return [String] Formatted log message
      def build_message(event_name, details)
        message = "[#{event_name}]"
        message += " #{format_details(details)}" unless details.empty?
        message
      end

      # Format details hash for logging
      # @param details [Hash] Details to format
      # @return [String] Formatted details
      def format_details(details)
        details.map { |k, v| "#{k}=#{format_value(v)}" }.join(' | ')
      end

      # Format a single value for logging
      # @param value [Object] Value to format
      # @return [String] Formatted value
      def format_value(value)
        case value
        when Array
          "[#{value.join(', ')}]"
        when Hash
          # Format hash recursively, handling nested values
          pairs = value.map do |k, v|
            formatted_v = case v
                          when Hash, Array
                            format_value(v)
                          when String
                            # Don't add quotes for simple values in nested hashes
                            v
                          else
                            v.to_s
                          end
            "#{k}: #{formatted_v}"
          end
          "{#{pairs.join(', ')}}"
        else
          value.to_s
        end
      end
    end
  end
end
