# frozen_string_literal: true

require "json"

module CodingAgentTools
  module Atoms
    module Mcp
      # Validates MCP protocol messages according to specification
      class ProtocolValidator
        # MCP protocol version supported
        SUPPORTED_VERSION = "2025-03-26"

        # Required fields for different message types
        REQUIRED_REQUEST_FIELDS = %w[jsonrpc id method].freeze
        REQUIRED_RESPONSE_FIELDS = %w[jsonrpc id].freeze
        REQUIRED_NOTIFICATION_FIELDS = %w[jsonrpc method].freeze

        class ValidationError < StandardError; end

        # Validate a JSON-RPC message for MCP compliance
        #
        # @param message [Hash] The parsed JSON message
        # @return [Boolean] true if valid
        # @raise [ValidationError] if invalid
        def self.validate_message!(message)
          unless message.is_a?(Hash)
            raise ValidationError, "Message must be a Hash"
          end

          validate_jsonrpc_version!(message)
          validate_message_structure!(message)

          true
        end

        # Validate JSON-RPC version
        #
        # @param message [Hash] The message to validate
        # @raise [ValidationError] if invalid version
        def self.validate_jsonrpc_version!(message)
          unless message["jsonrpc"] == "2.0"
            raise ValidationError, "Invalid jsonrpc version: #{message["jsonrpc"]}"
          end
        end

        # Validate message structure based on type
        #
        # @param message [Hash] The message to validate
        # @raise [ValidationError] if invalid structure
        def self.validate_message_structure!(message)
          if message.key?("id")
            if message.key?("method")
              # Request message
              validate_required_fields!(message, REQUIRED_REQUEST_FIELDS)
            else
              # Response message
              validate_required_fields!(message, REQUIRED_RESPONSE_FIELDS)
              validate_response_content!(message)
            end
          elsif message.key?("method")
            # Notification message
            validate_required_fields!(message, REQUIRED_NOTIFICATION_FIELDS)
          else
            raise ValidationError, "Invalid message structure: missing method or id"
          end
        end

        # Validate required fields are present
        #
        # @param message [Hash] The message to validate
        # @param required_fields [Array<String>] Required field names
        # @raise [ValidationError] if fields missing
        def self.validate_required_fields!(message, required_fields)
          missing_fields = required_fields - message.keys
          unless missing_fields.empty?
            raise ValidationError, "Missing required fields: #{missing_fields.join(", ")}"
          end
        end

        # Validate response message content
        #
        # @param message [Hash] The response message
        # @raise [ValidationError] if invalid response
        def self.validate_response_content!(message)
          has_result = message.key?("result")
          has_error = message.key?("error")

          if has_result && has_error
            raise ValidationError, "Response cannot have both result and error"
          end

          unless has_result || has_error
            raise ValidationError, "Response must have either result or error"
          end

          if has_error
            validate_error_object!(message["error"])
          end
        end

        # Validate error object structure
        #
        # @param error [Hash] The error object
        # @raise [ValidationError] if invalid error object
        def self.validate_error_object!(error)
          unless error.is_a?(Hash)
            raise ValidationError, "Error must be an object"
          end

          unless error.key?("code") && error.key?("message")
            raise ValidationError, "Error must have code and message fields"
          end

          unless error["code"].is_a?(Integer)
            raise ValidationError, "Error code must be an integer"
          end

          unless error["message"].is_a?(String)
            raise ValidationError, "Error message must be a string"
          end
        end

        # Validate MCP method name
        #
        # @param method [String] The method name
        # @return [Boolean] true if valid MCP method
        def self.valid_mcp_method?(method)
          return false unless method.is_a?(String)

          # Standard MCP methods
          mcp_methods = %w[
            initialize
            tools/list
            tools/call
            resources/list
            resources/read
            prompts/list
            prompts/get
            completion/complete
            logging/setLevel
          ]

          mcp_methods.include?(method) || method.start_with?("notifications/")
        end

        # Create a standard MCP error response
        #
        # @param id [String, Integer] Request ID
        # @param code [Integer] Error code
        # @param message [String] Error message
        # @param data [Hash, nil] Additional error data
        # @return [Hash] MCP error response
        def self.create_error_response(id, code, message, data = nil)
          error = {
            "jsonrpc" => "2.0",
            "id" => id,
            "error" => {
              "code" => code,
              "message" => message
            }
          }

          error["error"]["data"] = data if data

          error
        end

        # Standard MCP error codes
        module ErrorCodes
          PARSE_ERROR = -32700
          INVALID_REQUEST = -32600
          METHOD_NOT_FOUND = -32601
          INVALID_PARAMS = -32602
          INTERNAL_ERROR = -32603
          SERVER_ERROR_START = -32099
          SERVER_ERROR_END = -32000
        end
      end
    end
  end
end