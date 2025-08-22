# frozen_string_literal: true

require "json"

module CodingAgentTools
  module Organisms
    module Mcp
      # Stdio transport for MCP proxy (compatible with Claude Desktop)
      class StdioTransport
        def initialize(
          input: $stdin,
          output: $stdout,
          message_handler: nil,
          logger: nil
        )
          @input = input
          @output = output
          @message_handler = message_handler
          @logger = logger || default_logger
          @running = false
          @output_mutex = Mutex.new
        end

        # Start the stdio transport
        def start
          logger.info("Starting MCP stdio transport")
          @running = true

          begin
            # Start message processing loop
            process_messages
          rescue Interrupt
            logger.info("Received interrupt, shutting down...")
          rescue => e
            logger.error("Stdio transport error: #{e.message}")
            logger.error(e.backtrace.join("\n"))
          ensure
            stop
          end
        end

        # Stop the stdio transport
        def stop
          @running = false
          logger.info("Stopped MCP stdio transport")
        end

        # Send a message to output
        def send_message(message)
          output_mutex.synchronize do
            json_message = JSON.generate(message)
            output.puts(json_message)
            output.flush
          end
        rescue => e
          logger.error("Failed to send message: #{e.message}")
        end

        private

        attr_reader :input, :output, :message_handler, :logger, :output_mutex

        # Main message processing loop
        def process_messages
          while @running
            begin
              # Read line from input
              line = input.gets
              break unless line

              line = line.strip
              next if line.empty?

              # Parse and process message
              process_line(line)
            rescue EOFError
              logger.info("Input stream closed")
              break
            rescue => e
              logger.error("Error processing message: #{e.message}")
              # Continue processing other messages
            end
          end
        end

        # Process a single line of input
        def process_line(line)
          logger.debug("Received: #{line}")

          begin
            # Parse JSON message
            message = JSON.parse(line)

            # Validate and route message
            response = message_handler&.route_message(message)

            # Send response if this was a request (has id)
            if response && message["id"]
              send_message(response)
            end
          rescue JSON::ParserError => e
            logger.error("JSON parse error: #{e.message}")

            # Send parse error response if possible
            if message_id = extract_id_from_invalid_json(line)
              error_response = create_parse_error_response(message_id, e.message)
              send_message(error_response)
            end
          rescue => e
            logger.error("Message processing error: #{e.message}")

            # Send internal error response
            message_id = message&.dig("id")
            error_response = create_internal_error_response(message_id, e.message)
            send_message(error_response)
          end
        end

        # Try to extract ID from malformed JSON for error reporting
        def extract_id_from_invalid_json(line)
          # Simple regex to find id field in malformed JSON
          match = line.match(/"id"\s*:\s*([^,}]+)/)
          return nil unless match

          id_value = match[1].strip.gsub(/[",]/, "")

          # Try to parse as number or return as string
          if id_value.match?(/^\d+$/)
            id_value.to_i
          else
            id_value
          end
        rescue
          nil
        end

        # Create parse error response
        def create_parse_error_response(id, message)
          {
            "jsonrpc" => "2.0",
            "id" => id,
            "error" => {
              "code" => -32700,
              "message" => "Parse error: #{message}"
            }
          }
        end

        # Create internal error response
        def create_internal_error_response(id, message)
          {
            "jsonrpc" => "2.0",
            "id" => id,
            "error" => {
              "code" => -32603,
              "message" => "Internal error: #{message}"
            }
          }
        end

        def default_logger
          require "logger"
          # For stdio transport, log to stderr to avoid interfering with protocol
          Logger.new($stderr, level: Logger::WARN)
        end
      end
    end
  end
end
