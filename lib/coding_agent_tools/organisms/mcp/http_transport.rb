# frozen_string_literal: true

require "webrick"
require "json"
require "thread"

module CodingAgentTools
  module Organisms
    module Mcp
      # HTTP transport for MCP proxy with SSE support
      class HttpTransport
        def initialize(
          host: "localhost",
          port: 3000,
          message_handler: nil,
          logger: nil
        )
          @host = host
          @port = port
          @message_handler = message_handler
          @logger = logger || default_logger
          @server = nil
          @sessions = {}
          @session_mutex = Mutex.new
        end

        # Start the HTTP server
        def start
          logger.info("Starting MCP HTTP transport on #{host}:#{port}")

          @server = WEBrick::HTTPServer.new(
            Host: host,
            Port: port,
            Logger: webrick_logger,
            AccessLog: []
          )

          setup_routes
          setup_signal_handlers

          server.start
        rescue => e
          logger.error("Failed to start HTTP server: #{e.message}")
          raise
        end

        # Stop the HTTP server
        def stop
          return unless server

          logger.info("Stopping MCP HTTP transport")
          server.shutdown
          cleanup_sessions
        end

        private

        attr_reader :host, :port, :message_handler, :logger, :server, :sessions, :session_mutex

        # Setup HTTP routes
        def setup_routes
          # Main MCP endpoint - supports both POST and GET
          server.mount_proc("/mcp") do |req, res|
            handle_mcp_request(req, res)
          end

          # Health check endpoint
          server.mount_proc("/health") do |req, res|
            res.content_type = "application/json"
            res.body = JSON.generate({ status: "ok", timestamp: Time.now.iso8601 })
          end

          # CORS preflight
          server.mount_proc("/") do |req, res|
            if req.request_method == "OPTIONS"
              handle_cors_preflight(req, res)
            else
              res.status = 404
              res.body = "Not Found"
            end
          end
        end

        # Handle MCP requests (both POST and GET)
        def handle_mcp_request(req, res)
          # CORS headers
          set_cors_headers(res)

          # Validate Origin header for security
          unless valid_origin?(req["Origin"])
            res.status = 403
            res.body = "Forbidden: Invalid origin"
            return
          end

          case req.request_method
          when "POST"
            handle_post_request(req, res)
          when "GET"
            handle_get_request(req, res)
          else
            res.status = 405
            res.body = "Method Not Allowed"
          end
        rescue => e
          logger.error("Request handling error: #{e.message}")
          res.status = 500
          res.content_type = "application/json"
          res.body = JSON.generate({
            jsonrpc: "2.0",
            error: {
              code: -32603,
              message: "Internal server error"
            }
          })
        end

        # Handle POST requests (JSON-RPC messages)
        def handle_post_request(req, res)
          content_type = req.content_type
          accept_header = req["Accept"] || ""

          unless content_type&.include?("application/json")
            res.status = 400
            res.body = "Content-Type must be application/json"
            return
          end

          # Parse and validate request body
          begin
            request_body = req.body
            messages = JSON.parse(request_body)
          rescue JSON::ParserError => e
            res.status = 400
            res.content_type = "application/json"
            res.body = JSON.generate({
              jsonrpc: "2.0",
              error: {
                code: -32700,
                message: "Parse error: #{e.message}"
              }
            })
            return
          end

          # Handle batch or single message
          responses = process_messages(messages)

          # Determine response format based on Accept header
          if accept_header.include?("text/event-stream")
            handle_sse_response(req, res, responses)
          else
            # Standard JSON response
            res.content_type = "application/json"
            res.body = JSON.generate(responses)
          end
        end

        # Handle GET requests (for SSE)
        def handle_get_request(req, res)
          session_id = req["Mcp-Session-Id"]

          unless session_id
            res.status = 400
            res.body = "Missing Mcp-Session-Id header"
            return
          end

          # Start SSE stream
          handle_sse_stream(req, res, session_id)
        end

        # Process single or batch messages
        def process_messages(messages)
          if messages.is_a?(Array)
            # Batch request
            messages.map { |msg| process_single_message(msg) }
          else
            # Single request
            process_single_message(messages)
          end
        end

        # Process a single MCP message
        def process_single_message(message)
          return nil unless message_handler

          message_handler.route_message(message)
        rescue => e
          logger.error("Message processing error: #{e.message}")
          {
            jsonrpc: "2.0",
            id: message["id"],
            error: {
              code: -32603,
              message: "Internal error: #{e.message}"
            }
          }
        end

        # Handle SSE response for streaming
        def handle_sse_response(req, res, responses)
          res.content_type = "text/event-stream"
          res.chunked = true
          res["Cache-Control"] = "no-cache"
          res["Connection"] = "keep-alive"

          # Send responses as SSE events
          if responses.is_a?(Array)
            responses.each_with_index do |response, index|
              send_sse_event(res, response, "response", index)
            end
          else
            send_sse_event(res, responses, "response")
          end

          # Keep connection open briefly
          sleep(0.1)
        end

        # Handle persistent SSE stream
        def handle_sse_stream(req, res, session_id)
          res.content_type = "text/event-stream"
          res.chunked = true
          res["Cache-Control"] = "no-cache"
          res["Connection"] = "keep-alive"

          # Register session
          session = create_session(session_id)

          begin
            # Send initial connection event
            send_sse_event(res, { connected: true }, "connect")

            # Keep connection alive and handle any queued messages
            loop do
              if session[:queue] && !session[:queue].empty?
                message = session[:queue].shift
                send_sse_event(res, message, "message")
              end

              sleep(1)
              break if session[:closed]
            end
          ensure
            cleanup_session(session_id)
          end
        end

        # Send SSE event
        def send_sse_event(res, data, event_type = nil, id = nil)
          res.body << "id: #{id}\n" if id
          res.body << "event: #{event_type}\n" if event_type
          res.body << "data: #{JSON.generate(data)}\n\n"
        end

        # Session management
        def create_session(session_id)
          session_mutex.synchronize do
            sessions[session_id] = {
              id: session_id,
              created_at: Time.now,
              queue: [],
              closed: false
            }
          end
        end

        def cleanup_session(session_id)
          session_mutex.synchronize do
            sessions.delete(session_id)
          end
        end

        def cleanup_sessions
          session_mutex.synchronize do
            sessions.clear
          end
        end

        # CORS handling
        def set_cors_headers(res)
          res["Access-Control-Allow-Origin"] = "*"  # TODO: Make configurable
          res["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
          res["Access-Control-Allow-Headers"] = "Content-Type, Accept, Mcp-Session-Id"
          res["Access-Control-Expose-Headers"] = "Mcp-Session-Id"
        end

        def handle_cors_preflight(req, res)
          set_cors_headers(res)
          res.status = 200
          res.body = ""
        end

        def valid_origin?(origin)
          # TODO: Implement proper origin validation
          # For now, allow all origins (development mode)
          true
        end

        # Signal handling for graceful shutdown
        def setup_signal_handlers
          %w[INT TERM].each do |signal|
            trap(signal) do
              logger.info("Received #{signal}, shutting down...")
              stop
            end
          end
        end

        def default_logger
          require "logger"
          Logger.new($stdout, level: Logger::INFO)
        end

        def webrick_logger
          require "logger"
          Logger.new(File.open(File::NULL, "w"))
        end
      end
    end
  end
end