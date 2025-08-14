# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      # Agent command for managing and validating agents
      class Agent < Dry::CLI::Command
        desc "Manage and validate agents with dual compatibility (Claude Code / MCP proxy)"

        option :list, type: :boolean, default: false, aliases: ["l"],
          desc: "List all available agents"

        option :validate, type: :string, aliases: ["v"],
          desc: "Validate specific agent file"

        option :format, type: :string, values: ["summary", "detailed", "claude", "mcp"], 
          default: "summary", aliases: ["f"],
          desc: "Output format for agent information"

        option :agent_dir, type: :string, default: ".claude/agents",
          desc: "Directory containing agent files"

        option :compatibility, type: :string, values: ["all", "claude", "mcp"],
          default: "all", aliases: ["c"],
          desc: "Filter by compatibility type"

        example [
          "--list",
          "--list --format detailed",
          "--validate .claude/agents/git-commit-manager.md",
          "--list --compatibility claude",
          "--list --format mcp"
        ]

        def call(**options)
          begin
            if options[:list]
              list_agents(options)
            elsif options[:validate]
              validate_agent(options[:validate], options)
            else
              show_help
            end
            0
          rescue => e
            handle_error(e, options)
            1
          end
        end

        private

        def list_agents(options)
          agent_dir = options[:agent_dir]
          
          unless Dir.exist?(agent_dir)
            puts "Agent directory not found: #{agent_dir}"
            return
          end

          agent_files = Dir.glob(File.join(agent_dir, "*.md"))
          
          if agent_files.empty?
            puts "No agent files found in #{agent_dir}"
            return
          end

          puts format_agent_list(agent_files, options)
        end

        def validate_agent(agent_file, options)
          unless File.exist?(agent_file)
            puts "Agent file not found: #{agent_file}"
            return
          end

          # Simple validation for now - just check basic structure
          content = File.read(agent_file)
          
          validation_result = {
            file: agent_file,
            has_frontmatter: content.match?(/^---\s*\n.*?\n---\s*\n/m),
            has_name: content.match?(/^name:\s*\S+/m),
            has_description: content.match?(/^description:\s*\S+/m),
            has_tools: content.match?(/^tools:\s*\[.*\]|^tools:\s*\S+/m),
            has_context_definition: content.match?(/^## Context Definition/m),
            claude_compatible: false,
            mcp_enhanced: false
          }

          # Check Claude compatibility
          validation_result[:claude_compatible] = validation_result[:has_frontmatter] &&
                                                 validation_result[:has_name] &&
                                                 validation_result[:has_description] &&
                                                 validation_result[:has_tools]

          # Check MCP enhancements
          validation_result[:mcp_enhanced] = content.match?(/^mcp:/m) || 
                                           content.match?(/^context:/m)

          puts format_validation_result(validation_result, options)
        end

        def format_agent_list(agent_files, options)
          output = []
          
          case options[:format]
          when "summary"
            output << "Available Agents:"
            output << "=================="
            agent_files.each do |file|
              agent_name = File.basename(file, ".md")
              # Quick compatibility check
              content = File.read(file)
              claude_compat = content.match?(/^name:\s*\S+/m) && content.match?(/^tools:/m)
              mcp_enhanced = content.match?(/^mcp:/m)
              
              status_parts = []
              status_parts << "Claude" if claude_compat
              status_parts << "MCP+" if mcp_enhanced
              status = status_parts.empty? ? "Basic" : status_parts.join(" | ")
              
              output << "  #{agent_name.ljust(25)} [#{status}]"
            end
          
          when "detailed"
            output << "Detailed Agent Information:"
            output << "=========================="
            agent_files.each do |file|
              agent_name = File.basename(file, ".md")
              content = File.read(file)
              
              # Extract basic metadata
              name_match = content.match(/^name:\s*(.+)$/m)
              desc_match = content.match(/^description:\s*(.+)$/m)
              tools_match = content.match(/^tools:\s*(.+)$/m)
              
              output << "\n#{agent_name}:"
              output << "  File: #{file}"
              output << "  Name: #{name_match ? name_match[1].strip : 'Not found'}"
              output << "  Description: #{desc_match ? desc_match[1].strip.gsub(/\s+/, ' ')[0..80] + '...' : 'Not found'}"
              output << "  Tools: #{tools_match ? tools_match[1].strip : 'Not found'}"
              
              # Compatibility info
              claude_compat = name_match && desc_match && tools_match
              mcp_enhanced = content.match?(/^mcp:/m)
              context_def = content.match?(/^## Context Definition/m)
              
              output << "  Claude Compatible: #{claude_compat ? 'Yes' : 'No'}"
              output << "  MCP Enhanced: #{mcp_enhanced ? 'Yes' : 'No'}"
              output << "  Context Definition: #{context_def ? 'Yes' : 'No'}"
            end

          when "claude"
            output << "Claude Code Compatible Agents:"
            output << "=============================="
            agent_files.each do |file|
              content = File.read(file)
              if content.match?(/^name:\s*\S+/m) && content.match?(/^tools:/m)
                agent_name = File.basename(file, ".md")
                desc_match = content.match(/^description:\s*(.+)$/m)
                description = desc_match ? desc_match[1].strip.gsub(/\s+/, ' ')[0..50] + '...' : ''
                output << "  #{agent_name}: #{description}"
              end
            end

          when "mcp"
            output << "MCP Proxy Enhanced Agents:"
            output << "=========================="
            agent_files.each do |file|
              content = File.read(file)
              if content.match?(/^mcp:/m)
                agent_name = File.basename(file, ".md")
                
                # Try to extract model info
                model_match = content.match(/^\s*model:\s*(.+)$/m)
                model = model_match ? model_match[1].strip : 'Not specified'
                
                output << "  #{agent_name}:"
                output << "    Model: #{model}"
                
                # Security settings
                if content.match?(/^\s*security:/m)
                  output << "    Security: Configured"
                end
                
                # Context injection
                if content.match?(/^\s*auto_inject:\s*true/m)
                  output << "    Context: Auto-injection enabled"
                end
              end
            end
          end

          output.join("\n")
        end

        def format_validation_result(result, options)
          output = []
          output << "Agent Validation Results:"
          output << "========================"
          output << "File: #{result[:file]}"
          output << ""
          
          output << "Structure Checks:"
          output << "  YAML Frontmatter: #{result[:has_frontmatter] ? '✓' : '✗'}"
          output << "  Name Field: #{result[:has_name] ? '✓' : '✗'}"
          output << "  Description Field: #{result[:has_description] ? '✓' : '✗'}"
          output << "  Tools Field: #{result[:has_tools] ? '✓' : '✗'}"
          output << "  Context Definition: #{result[:has_context_definition] ? '✓' : '✗'}"
          output << ""
          
          output << "Compatibility:"
          output << "  Claude Code Compatible: #{result[:claude_compatible] ? '✓' : '✗'}"
          output << "  MCP Proxy Enhanced: #{result[:mcp_enhanced] ? '✓' : '✗'}"
          
          if result[:claude_compatible] && result[:mcp_enhanced]
            output << ""
            output << "✓ This agent supports dual compatibility!"
          elsif result[:claude_compatible]
            output << ""
            output << "ℹ  This agent is Claude Code compatible but could be enhanced for MCP proxy"
          elsif result[:mcp_enhanced]
            output << ""
            output << "⚠  This agent has MCP enhancements but may not work with Claude Code"
          else
            output << ""
            output << "✗ This agent needs updates for compatibility"
          end

          output.join("\n")
        end

        def show_help
          puts <<~HELP
            Agent Management Tool
            
            Usage:
              agent --list                    # List all agents
              agent --validate <file>         # Validate specific agent
              
            Options:
              --format summary|detailed|claude|mcp    # Output format
              --compatibility all|claude|mcp          # Filter by compatibility
              --agent-dir <path>                      # Agent directory (default: .claude/agents)
              
            Examples:
              agent --list --format detailed
              agent --validate .claude/agents/git-commit-manager.md
              agent --list --compatibility mcp
          HELP
        end

        def handle_error(error, options)
          puts "Error: #{error.message}"
          puts "Use --help for usage information"
        end
      end
    end
  end
end