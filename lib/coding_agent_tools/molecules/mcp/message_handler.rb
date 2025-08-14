# frozen_string_literal: true

require "json"

module CodingAgentTools
  module Molecules
    module Mcp
      # Handles parsing, routing, and formatting of MCP messages
      class MessageHandler
        def initialize(tool_wrapper: nil, security_validator: nil, logger: nil)
          @tool_wrapper = tool_wrapper
          @security_validator = security_validator
          @logger = logger || default_logger
        end

        # Parse incoming MCP message from JSON
        #
        # @param json_data [String] Raw JSON message
        # @return [Hash] Parsed message
        # @raise [JSON::ParserError] if invalid JSON
        def parse_message(json_data)
          JSON.parse(json_data)
        rescue JSON::ParserError => e
          @logger.error("JSON parse error: #{e.message}")
          raise
        end

        # Route message to appropriate handler
        #
        # @param message [Hash] Parsed MCP message
        # @return [Hash] Response message
        def route_message(message)
          # Validate the message first
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.validate_message!(message)

          method = message["method"]
          params = message["params"] || {}
          id = message["id"]

          case method
          when "initialize"
            handle_initialize(id, params)
          when "tools/list"
            handle_tools_list(id, params)
          when "tools/call"
            handle_tools_call(id, params)
          when "resources/list"
            handle_resources_list(id, params)
          when "resources/read"
            handle_resources_read(id, params)
          when "prompts/list"
            handle_prompts_list(id, params)
          when "prompts/get"
            handle_prompts_get(id, params)
          when "completion/complete"
            handle_completion_complete(id, params)
          else
            create_method_not_found_error(id, method)
          end
        rescue CodingAgentTools::Atoms::Mcp::ProtocolValidator::ValidationError => e
          @logger.error("Protocol validation error: #{e.message}")
          create_invalid_request_error(message["id"], e.message)
        rescue => e
          @logger.error("Message routing error: #{e.message}")
          create_internal_error(message["id"], e.message)
        end

        # Format response as JSON
        #
        # @param response [Hash] Response object
        # @return [String] JSON formatted response
        def format_response(response)
          JSON.generate(response)
        end

        private

        attr_reader :tool_wrapper, :security_validator, :logger

        # Handle initialize request
        def handle_initialize(id, params)
          {
            "jsonrpc" => "2.0",
            "id" => id,
            "result" => {
              "protocolVersion" => "2025-03-26",
              "capabilities" => {
                "tools" => {
                  "listChanged" => false
                },
                "resources" => {
                  "subscribe" => false,
                  "listChanged" => false
                },
                "prompts" => {
                  "listChanged" => false
                },
                "completion" => {
                  "providers" => ["text"]
                }
              },
              "serverInfo" => {
                "name" => "coding-agent-tools-mcp-proxy",
                "version" => "0.1.0"
              }
            }
          }
        end

        # Handle tools list request
        def handle_tools_list(id, params)
          tools = tool_wrapper ? tool_wrapper.list_tools : []

          {
            "jsonrpc" => "2.0",
            "id" => id,
            "result" => {
              "tools" => tools
            }
          }
        end

        # Handle tool call request
        def handle_tools_call(id, params)
          tool_name = params["name"]
          arguments = params["arguments"] || {}

          unless tool_name
            return create_invalid_params_error(id, "Missing tool name")
          end

          # Security validation
          if security_validator && !security_validator.validate_tool_access(tool_name, arguments)
            return create_security_error(id, "Tool access denied")
          end

          result = tool_wrapper ? tool_wrapper.call_tool(tool_name, arguments) : nil

          if result
            {
              "jsonrpc" => "2.0",
              "id" => id,
              "result" => {
                "content" => [
                  {
                    "type" => "text",
                    "text" => result[:output] || ""
                  }
                ],
                "isError" => result[:error] || false
              }
            }
          else
            create_tool_not_found_error(id, tool_name)
          end
        end

        # Handle resources list request
        def handle_resources_list(id, params)
          {
            "jsonrpc" => "2.0",
            "id" => id,
            "result" => {
              "resources" => []
            }
          }
        end

        # Handle resource read request
        def handle_resources_read(id, params)
          create_method_not_implemented_error(id, "resources/read")
        end

        # Handle prompts list request
        def handle_prompts_list(id, params)
          {
            "jsonrpc" => "2.0",
            "id" => id,
            "result" => {
              "prompts" => []
            }
          }
        end

        # Handle prompt get request
        def handle_prompts_get(id, params)
          create_method_not_implemented_error(id, "prompts/get")
        end

        # Handle completion request
        def handle_completion_complete(id, params)
          create_method_not_implemented_error(id, "completion/complete")
        end

        # Error response helpers

        def create_method_not_found_error(id, method)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            CodingAgentTools::Atoms::Mcp::ProtocolValidator::ErrorCodes::METHOD_NOT_FOUND,
            "Method not found: #{method}"
          )
        end

        def create_invalid_request_error(id, message)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            CodingAgentTools::Atoms::Mcp::ProtocolValidator::ErrorCodes::INVALID_REQUEST,
            "Invalid request: #{message}"
          )
        end

        def create_invalid_params_error(id, message)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            CodingAgentTools::Atoms::Mcp::ProtocolValidator::ErrorCodes::INVALID_PARAMS,
            "Invalid parameters: #{message}"
          )
        end

        def create_internal_error(id, message)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            CodingAgentTools::Atoms::Mcp::ProtocolValidator::ErrorCodes::INTERNAL_ERROR,
            "Internal error: #{message}"
          )
        end

        def create_security_error(id, message)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            -32001, # Custom security error code
            message
          )
        end

        def create_tool_not_found_error(id, tool_name)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            -32002, # Custom tool not found error code
            "Tool not found: #{tool_name}"
          )
        end

        def create_method_not_implemented_error(id, method)
          CodingAgentTools::Atoms::Mcp::ProtocolValidator.create_error_response(
            id,
            -32003, # Custom not implemented error code
            "Method not implemented: #{method}"
          )
        end

        def default_logger
          require "logger"
          Logger.new($stderr, level: Logger::WARN)
        end
      end
    end
  end
end