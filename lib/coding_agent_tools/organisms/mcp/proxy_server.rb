# frozen_string_literal: true

require "yaml"
require "logger"

module CodingAgentTools
  module Organisms
    module Mcp
      # Main MCP proxy server that orchestrates transports and message handling
      class ProxyServer
        def initialize(options = {})
          @options = options
          @logger = setup_logger(options[:verbose])
          @config = load_configuration(options[:config])
          
          # Initialize core components
          @security_validator = create_security_validator
          @tool_wrapper = create_tool_wrapper
          @message_handler = create_message_handler
          @transport = create_transport
        end

        # Start the proxy server
        def start
          logger.info("Starting MCP Proxy Server")
          logger.info("Configuration: #{config_summary}")
          
          validate_configuration!
          transport.start
        rescue => e
          logger.error("Failed to start proxy server: #{e.message}")
          logger.error(e.backtrace.join("\n")) if options[:verbose]
          raise
        end

        # Stop the proxy server
        def stop
          logger.info("Stopping MCP Proxy Server")
          transport.stop if transport.respond_to?(:stop)
        end

        private

        attr_reader :options, :config, :logger, :security_validator, :tool_wrapper, :message_handler, :transport

        # Load configuration from file or use defaults
        def load_configuration(config_path)
          if config_path && File.exist?(config_path)
            logger.info("Loading configuration from: #{config_path}")
            
            case File.extname(config_path).downcase
            when '.yaml', '.yml'
              YAML.load_file(config_path)
            when '.json'
              require 'json'
              JSON.parse(File.read(config_path))
            else
              raise "Unsupported configuration format: #{config_path}"
            end
          else
            logger.info("Using default configuration")
            default_configuration
          end
        rescue => e
          logger.error("Failed to load configuration: #{e.message}")
          raise
        end

        # Setup logger based on options
        def setup_logger(verbose)
          level = verbose ? Logger::DEBUG : Logger::INFO
          
          # For stdio transport, log to stderr to avoid protocol interference
          if options[:stdio]
            Logger.new($stderr, level: level)
          else
            Logger.new($stdout, level: level)
          end
        end

        # Create security validator with configuration
        def create_security_validator
          CodingAgentTools::Molecules::Mcp::SecurityValidator.new(
            config: config,
            logger: logger
          )
        end

        # Create tool wrapper with configuration
        def create_tool_wrapper
          CodingAgentTools::Molecules::Mcp::ToolWrapper.new(
            tool_config: config,
            logger: logger
          )
        end

        # Create message handler with dependencies
        def create_message_handler
          CodingAgentTools::Molecules::Mcp::MessageHandler.new(
            tool_wrapper: tool_wrapper,
            security_validator: security_validator,
            logger: logger
          )
        end

        # Create appropriate transport based on options
        def create_transport
          if options[:stdio]
            logger.info("Using stdio transport")
            CodingAgentTools::Organisms::Mcp::StdioTransport.new(
              message_handler: message_handler,
              logger: logger
            )
          else
            logger.info("Using HTTP transport on #{options[:host]}:#{options[:port]}")
            CodingAgentTools::Organisms::Mcp::HttpTransport.new(
              host: options[:host],
              port: options[:port],
              message_handler: message_handler,
              logger: logger
            )
          end
        end

        # Validate configuration before starting
        def validate_configuration!
          errors = []

          # Validate tools configuration
          if config["tools"] && config["tools"]["expose"]
            exposed_tools = config["tools"]["expose"]
            unless exposed_tools.is_a?(Hash)
              errors << "tools.expose must be a hash"
            end
          end

          # Validate security configuration
          if config["security"]
            security_config = config["security"]
            
            if security_config["rate_limit"] && !security_config["rate_limit"].match?(/\d+\/(second|minute|hour|day)/)
              errors << "security.rate_limit must be in format 'N/unit' (e.g., '100/hour')"
            end
          end

          # Validate routing configuration
          if config["routing"]
            routing_config = config["routing"]
            
            if routing_config["default_model"] && !routing_config["default_model"].is_a?(String)
              errors << "routing.default_model must be a string"
            end
          end

          unless errors.empty?
            raise "Configuration validation failed:\n#{errors.join("\n")}"
          end
        end

        # Generate configuration summary for logging
        def config_summary
          summary = {}
          
          if config["tools"] && config["tools"]["expose"]
            summary[:exposed_tools] = config["tools"]["expose"].keys
          end
          
          if config["security"]
            summary[:security] = {
              rate_limit: config["security"]["rate_limit"],
              allowed_paths: config["security"]["allowed_paths"]&.length,
              forbidden_paths: config["security"]["forbidden_paths"]&.length
            }
          end
          
          if config["routing"]
            summary[:routing] = {
              default_model: config["routing"]["default_model"]
            }
          end
          
          summary
        end

        # Default configuration
        def default_configuration
          {
            "tools" => {
              "expose" => {
                "git-status" => true,
                "git-commit" => {
                  "require_confirmation" => true
                },
                "task-manager" => {
                  "methods" => ["list", "next", "create"]
                },
                "nav-ls" => true,
                "nav-tree" => true,
                "context" => true,
                "llm-query" => {
                  "require_confirmation" => false
                }
              }
            },
            "security" => {
              "allowed_paths" => ["dev-taskflow/**", "docs/**", "dev-handbook/**"],
              "forbidden_paths" => [".env", "secrets/**", "*.key", "*.pem"],
              "rate_limit" => "100/hour"
            },
            "routing" => {
              "default_model" => "google:gemini-2.5-flash",
              "complex_tasks" => "anthropic:claude-3-5-sonnet"
            },
            "agents" => {
              "directory" => ".claude/agents/",
              "auto_discover" => true
            }
          }
        end
      end
    end
  end
end