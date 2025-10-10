# frozen_string_literal: true

require "pathname"

module CodingAgentTools
  module Molecules
    module Mcp
      # Validates security constraints for MCP tool access
      class SecurityValidator
        def initialize(config: nil, logger: nil)
          @config = config || default_security_config
          @logger = logger || default_logger
          @rate_limiter = RateLimiter.new(config&.dig("security", "rate_limit"))
        end

        # Validate tool access permissions
        #
        # @param tool_name [String] Name of the tool
        # @param arguments [Hash] Tool arguments
        # @return [Boolean] true if access allowed
        def validate_tool_access(tool_name, arguments)
          # Check rate limiting
          unless rate_limiter.allow_request?
            logger.warn("Rate limit exceeded for tool access")
            return false
          end

          # Check if tool is in allowed list
          unless tool_allowed?(tool_name)
            logger.warn("Tool not in allowed list: #{tool_name}")
            return false
          end

          # Validate any path arguments
          unless validate_path_arguments(arguments)
            logger.warn("Invalid path in arguments for tool: #{tool_name}")
            return false
          end

          # Check for forbidden patterns
          unless validate_argument_content(arguments)
            logger.warn("Forbidden content in arguments for tool: #{tool_name}")
            return false
          end

          true
        end

        # Validate and sanitize file paths
        #
        # @param path [String] File path to validate
        # @return [String, nil] Sanitized path or nil if invalid
        def validate_and_sanitize_path(path)
          return nil unless path.is_a?(String)
          return nil if path.empty?

          # Resolve path to prevent directory traversal
          begin
            resolved_path = Pathname.new(path).cleanpath.to_s
          rescue
            return nil
          end

          # Check for directory traversal attempts
          if resolved_path.include?("..") || resolved_path.start_with?("/")
            logger.warn("Directory traversal attempt blocked: #{path}")
            return nil
          end

          # Check against allowed paths
          allowed_paths = config.dig("security", "allowed_paths") || []
          forbidden_paths = config.dig("security", "forbidden_paths") || default_forbidden_paths

          # Check if path is in forbidden list
          if path_matches_patterns?(resolved_path, forbidden_paths)
            logger.warn("Forbidden path access blocked: #{resolved_path}")
            return nil
          end

          # Check if path is in allowed list (if allowed paths are specified)
          if !allowed_paths.empty? && !path_matches_patterns?(resolved_path, allowed_paths)
            logger.warn("Path not in allowed list: #{resolved_path}")
            return nil
          end

          resolved_path
        end

        # Sanitize log output to remove sensitive information
        #
        # @param content [String] Content to sanitize
        # @return [String] Sanitized content
        def sanitize_log_content(content)
          return "" unless content.is_a?(String)

          sanitized = content.dup

          # Remove common secrets patterns
          secret_patterns = [
            /(?i)(password|secret|key|token|api[_-]?key)[\s\=\:]+[^\s\n]+/,
            /(?i)bearer\s+[a-zA-Z0-9\-_\.]+/,
            /(?i)authorization[\s\:]+[^\s\n]+/,
            /[a-zA-Z0-9]{32,}/  # Long alphanumeric strings (potential tokens)
          ]

          secret_patterns.each do |pattern|
            sanitized.gsub!(pattern, "[REDACTED]")
          end

          sanitized
        end

        private

        attr_reader :config, :logger, :rate_limiter

        # Check if tool is allowed
        def tool_allowed?(tool_name)
          exposed_tools = config.dig("tools", "expose") || {}
          exposed_tools.key?(tool_name)
        end

        # Validate path arguments in tool parameters
        def validate_path_arguments(arguments)
          path_keys = %w[path file directory dir filepath filename]

          path_keys.each do |key|
            if arguments.key?(key)
              path_value = arguments[key]
              sanitized = validate_and_sanitize_path(path_value)
              return false unless sanitized
            end
          end

          true
        end

        # Validate argument content for forbidden patterns
        def validate_argument_content(arguments)
          return true unless arguments.is_a?(Hash)

          forbidden_patterns = [
            /\$\(.*\)/,  # Command substitution
            /`.*`/,      # Backticks
            /;\s*rm\s/,  # Dangerous commands
            /;\s*sudo\s/,
            /&&\s*rm\s/,
            /\|\s*rm\s/
          ]

          arguments.each_value do |value|
            next unless value.is_a?(String)

            forbidden_patterns.each do |pattern|
              if value.match?(pattern)
                logger.warn("Forbidden pattern detected: #{pattern}")
                return false
              end
            end
          end

          true
        end

        # Check if path matches any of the given patterns
        def path_matches_patterns?(path, patterns)
          patterns.any? do |pattern|
            if pattern.include?("*")
              # Simple glob pattern matching
              File.fnmatch(pattern, path)
            else
              path.start_with?(pattern)
            end
          end
        end

        # Default security configuration
        def default_security_config
          {
            "tools" => {
              "expose" => {}
            },
            "security" => {
              "allowed_paths" => ["dev-taskflow/**", "docs/**"],
              "forbidden_paths" => default_forbidden_paths,
              "rate_limit" => "100/hour"
            }
          }
        end

        # Default forbidden paths
        def default_forbidden_paths
          %w[
            .env
            .env.*
            secrets/**
            *.key
            *.pem
            *.p12
            ~/.ssh/**
            /etc/**
            /var/**
            /usr/**
            /bin/**
            /sbin/**
          ]
        end

        def default_logger
          require "logger"
          Logger.new($stderr, level: Logger::WARN)
        end

        # Simple rate limiter implementation
        class RateLimiter
          def initialize(limit_spec)
            @limit_spec = limit_spec
            @requests = []
            parse_limit_spec
          end

          def allow_request?
            return true unless @max_requests && @time_window

            now = Time.now
            # Remove old requests outside the time window
            @requests.reject! { |timestamp| now - timestamp > @time_window }

            if @requests.length >= @max_requests
              false
            else
              @requests << now
              true
            end
          end

          private

          def parse_limit_spec
            return unless @limit_spec

            if @limit_spec =~ /(\d+)\/(\w+)/
              @max_requests = $1.to_i
              unit = $2.downcase

              @time_window = case unit
              when "second", "sec", "s"
                1
              when "minute", "min", "m"
                60
              when "hour", "hr", "h"
                3600
              when "day", "d"
                86400
              else
                3600  # Default to hour
              end
            end
          end
        end
      end
    end
  end
end
