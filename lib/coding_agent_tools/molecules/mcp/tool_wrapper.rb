# frozen_string_literal: true

require "open3"
require "json"

module CodingAgentTools
  module Molecules
    module Mcp
      # Wraps dev-tools executables as MCP tools
      class ToolWrapper
        def initialize(tool_config: nil, logger: nil)
          @tool_config = tool_config || default_tool_config
          @logger = logger || default_logger
          @exe_path = determine_exe_path
        end

        # List all available tools
        #
        # @return [Array<Hash>] Array of tool definitions
        def list_tools
          exposed_tools = tool_config.dig("tools", "expose") || {}

          exposed_tools.map do |tool_name, config|
            tool_definition = {
              "name" => tool_name,
              "description" => get_tool_description(tool_name),
              "inputSchema" => get_tool_schema(tool_name, config)
            }

            # Add any additional metadata from config
            if config.is_a?(Hash)
              tool_definition["requireConfirmation"] = config["require_confirmation"] if config["require_confirmation"]
              tool_definition["methods"] = config["methods"] if config["methods"]
            end

            tool_definition
          end
        end

        # Call a specific tool
        #
        # @param tool_name [String] Name of the tool to call
        # @param arguments [Hash] Tool arguments
        # @return [Hash] Tool execution result
        def call_tool(tool_name, arguments = {})
          # Check if tool is exposed
          exposed_tools = tool_config.dig("tools", "expose") || {}
          tool_config_entry = exposed_tools[tool_name]

          unless tool_config_entry
            return {
              error: true,
              output: "Tool not exposed: #{tool_name}"
            }
          end

          # Build command
          command = build_command(tool_name, arguments, tool_config_entry)
          logger.info("Executing tool: #{command.join(" ")}")

          # Execute command
          execute_command(command)
        end

        private

        attr_reader :tool_config, :logger, :exe_path

        # Determine the path to the exe directory
        def determine_exe_path
          # Try to find exe directory relative to current location
          current_dir = File.dirname(__FILE__)
          possible_paths = [
            File.join(current_dir, "../../../exe"),
            File.join(current_dir, "../../../../exe"),
            File.join(Dir.pwd, "dev-tools/exe"),
            File.join(Dir.pwd, "exe")
          ]

          possible_paths.each do |path|
            return File.expand_path(path) if File.directory?(path)
          end

          # Fallback: assume tools are in PATH
          nil
        end

        # Get tool description from help output or predefined descriptions
        def get_tool_description(tool_name)
          descriptions = {
            "git-status" => "Show git repository status with enhanced formatting",
            "git-commit" => "Create intelligent git commits with AI-generated messages",
            "git-add" => "Enhanced git add with interactive options",
            "git-diff" => "Enhanced git diff with formatting options",
            "task-manager" => "Manage project tasks and todo items",
            "nav-ls" => "Enhanced directory listing with smart filtering",
            "nav-tree" => "Display project tree structure",
            "llm-query" => "Query LLM providers with unified interface",
            "context" => "Load and format project context",
            "handbook" => "Access development handbook and templates"
          }

          descriptions[tool_name] || "Development tool: #{tool_name}"
        end

        # Get tool input schema
        def get_tool_schema(tool_name, config)
          # Basic schema - in a real implementation, we could parse --help output
          # or maintain a registry of schemas
          base_schema = {
            "type" => "object",
            "properties" => {},
            "required" => []
          }

          # Add tool-specific properties based on known tools
          case tool_name
          when "git-status"
            base_schema["properties"] = {
              "verbose" => { "type" => "boolean", "description" => "Show detailed status" },
              "short" => { "type" => "boolean", "description" => "Show short status" }
            }
          when "git-commit"
            base_schema["properties"] = {
              "intention" => { "type" => "string", "description" => "Commit intention/context" },
              "all" => { "type" => "boolean", "description" => "Stage all changes" },
              "message" => { "type" => "string", "description" => "Commit message" }
            }
          when "task-manager"
            if config.is_a?(Hash) && config["methods"]
              # Restrict to specific methods
              base_schema["properties"]["method"] = {
                "type" => "string",
                "enum" => config["methods"],
                "description" => "Task manager method to call"
              }
              base_schema["required"] = ["method"]
            else
              base_schema["properties"]["method"] = {
                "type" => "string",
                "enum" => ["list", "next", "create", "recent"],
                "description" => "Task manager method to call"
              }
            end
          when "llm-query"
            base_schema["properties"] = {
              "model" => { "type" => "string", "description" => "LLM model to use" },
              "prompt" => { "type" => "string", "description" => "Query prompt" },
              "system" => { "type" => "string", "description" => "System instruction" }
            }
            base_schema["required"] = ["prompt"]
          when "nav-ls"
            base_schema["properties"] = {
              "path" => { "type" => "string", "description" => "Directory path to list" },
              "long" => { "type" => "boolean", "description" => "Use long format" },
              "all" => { "type" => "boolean", "description" => "Show hidden files" }
            }
          end

          base_schema
        end

        # Build command array from tool name, arguments, and config
        def build_command(tool_name, arguments, config)
          command = []

          # Add executable path
          if exe_path
            executable = File.join(exe_path, tool_name)
            command << executable if File.executable?(executable)
          end

          # Fallback to tool name if not found in exe path
          command << tool_name if command.empty?

          # Add arguments based on tool and schema
          case tool_name
          when "git-status"
            command << "--verbose" if arguments["verbose"]
            command << "--short" if arguments["short"]
          when "git-commit"
            if arguments["intention"]
              command << "--intention" << arguments["intention"]
            end
            command << "--all" if arguments["all"]
            if arguments["message"]
              command << "--message" << arguments["message"]
            end
          when "task-manager"
            command << arguments["method"] if arguments["method"]
          when "llm-query"
            if arguments["model"]
              command << "--model" << arguments["model"]
            end
            if arguments["system"]
              command << "--system" << arguments["system"]
            end
            command << arguments["prompt"] if arguments["prompt"]
          when "nav-ls"
            command << "--long" if arguments["long"]
            command << "--all" if arguments["all"]
            command << arguments["path"] if arguments["path"]
          end

          command
        end

        # Execute command and capture output
        def execute_command(command)
          stdout, stderr, status = Open3.capture3(*command)

          {
            output: stdout,
            error: !status.success?,
            exit_code: status.exitstatus,
            stderr: stderr
          }
        rescue => e
          logger.error("Command execution failed: #{e.message}")
          {
            output: "Command execution failed: #{e.message}",
            error: true,
            exit_code: 1,
            stderr: e.message
          }
        end

        # Default tool configuration
        def default_tool_config
          {
            "tools" => {
              "expose" => {
                "git-status" => true,
                "git-commit" => {
                  "require_confirmation" => true
                },
                "task-manager" => {
                  "methods" => ["list", "next"]
                },
                "nav-ls" => true,
                "context" => true
              }
            }
          }
        end

        def default_logger
          require "logger"
          Logger.new($stderr, level: Logger::WARN)
        end
      end
    end
  end
end