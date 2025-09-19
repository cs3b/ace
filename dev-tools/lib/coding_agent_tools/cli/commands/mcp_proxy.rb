# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      # MCP Proxy server command
      class McpProxy < Dry::CLI::Command
        desc "Start MCP proxy server"

        option :port, type: :integer, default: 3000, desc: "Port to bind HTTP server"
        option :host, type: :string, default: "localhost", desc: "Host to bind HTTP server"
        option :stdio, type: :boolean, default: false, desc: "Use stdio transport instead of HTTP"
        option :config, type: :string, desc: "Configuration file path"
        option :verbose, type: :boolean, default: false, desc: "Enable verbose logging"

        example [
          "--port 3000                    # Start HTTP server on port 3000",
          "--stdio                        # Use stdio transport for Claude Desktop",
          "--config proxy-config.yaml     # Use configuration file",
          "--verbose                      # Enable verbose logging"
        ]

        def call(port: 3000, host: "localhost", stdio: false, config: nil, verbose: false, **)
          require_relative "../../organisms/mcp/proxy_server"

          server_options = {
            port: port,
            host: host,
            stdio: stdio,
            config: config,
            verbose: verbose
          }

          proxy_server = CodingAgentTools::Organisms::Mcp::ProxyServer.new(server_options)
          proxy_server.start
        rescue => e
          warn "Error starting MCP proxy: #{e.message}"
          warn e.backtrace.join("\n") if verbose
          exit 1
        end
      end
    end
  end
end
