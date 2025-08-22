# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module Agents
      # MetadataExtractor - Molecule for extracting specific metadata from agent structures
      #
      # Responsibilities:
      # - Extract Claude Code compatible fields
      # - Extract MCP proxy specific configuration
      # - Handle graceful degradation for missing fields
      # - Provide metadata transformation utilities
      class MetadataExtractor
        # Extract metadata for Claude Code compatibility
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Claude-compatible metadata
        def self.extract_claude_fields(agent_data)
          return {} unless agent_data && agent_data[:core]

          core = agent_data[:core]
          claude_metadata = {}

          # Required fields for Claude Code
          claude_metadata[:name] = core[:name] if core[:name]
          claude_metadata[:description] = core[:description] if core[:description]
          claude_metadata[:type] = core[:type] if core[:type]

          # Tools field - handle both array and string formats
          if core[:tools]
            claude_metadata[:tools] = normalize_tools_field(core[:tools])
          end

          # Optional fields that Claude Code can use
          claude_metadata[:last_modified] = core[:last_modified] if core[:last_modified]

          claude_metadata
        end

        # Extract MCP proxy specific configuration
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] MCP proxy configuration
        def self.extract_mcp_config(agent_data)
          return {} unless agent_data

          mcp_config = {
            core: agent_data[:core] || {},
            mcp: agent_data[:mcp] || {},
            context: agent_data[:context] || {}
          }

          # Add computed fields for MCP routing
          mcp_config[:computed] = compute_mcp_routing(agent_data)

          mcp_config
        end

        # Extract model routing information for MCP
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Model routing configuration
        def self.extract_model_routing(agent_data)
          mcp_data = agent_data&.dig(:mcp) || {}
          routing_config = {}

          # Primary model assignment
          routing_config[:primary_model] = mcp_data[:model] if mcp_data[:model]

          # Routing rules
          if mcp_data[:routing]
            routing_config.merge!(mcp_data[:routing])
          end

          # Default fallbacks if not specified
          routing_config[:complexity_threshold] ||= "medium"
          routing_config[:fallback_model] ||= "google:gemini-2.5-flash"

          routing_config
        end

        # Extract security configuration for MCP
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Security configuration
        def self.extract_security_config(agent_data)
          mcp_data = agent_data&.dig(:mcp) || {}
          security_config = mcp_data[:security] || {}

          # Normalize path arrays
          if security_config[:allowed_paths]
            security_config[:allowed_paths] = Array(security_config[:allowed_paths])
          end

          if security_config[:forbidden_paths]
            security_config[:forbidden_paths] = Array(security_config[:forbidden_paths])
          end

          # Default rate limiting if not specified
          security_config[:rate_limit] ||= "50/hour"

          security_config
        end

        # Extract tools mapping configuration for MCP
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Tools mapping configuration
        def self.extract_tools_mapping(agent_data)
          mcp_data = agent_data&.dig(:mcp) || {}
          tools_mapping = mcp_data[:tools_mapping] || {}

          # Ensure all tools from core are represented in mapping
          core_tools = normalize_tools_field(agent_data&.dig(:core, :tools))

          core_tools.each do |tool|
            unless tools_mapping[tool.to_sym] || tools_mapping[tool]
              # Provide default mapping for tools not explicitly configured
              tools_mapping[tool] = {expose: true}
            end
          end

          tools_mapping
        end

        # Extract context configuration
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Context configuration
        def self.extract_context_config(agent_data)
          context_data = agent_data&.dig(:context) || {}

          # Default values for context configuration
          {
            auto_inject: context_data[:auto_inject] || false,
            template: context_data[:template] || "embedded",
            cache_ttl: context_data[:cache_ttl] || 300
          }
        end

        # Check if agent has MCP enhancements
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Boolean] True if agent has MCP-specific features
        def self.mcp_enhanced?(agent_data)
          return false unless agent_data

          mcp_data = agent_data[:mcp] || {}
          context_data = agent_data[:context] || {}

          # Has MCP enhancements if any MCP-specific fields are present
          !mcp_data.empty? || context_data[:auto_inject] || context_data[:template] == "embedded"
        end

        # Check Claude Code compatibility
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Boolean] True if agent is compatible with Claude Code
        def self.claude_compatible?(agent_data)
          return false unless agent_data && agent_data[:core]

          core = agent_data[:core]

          # Must have required fields
          required_fields = [:name, :description, :tools, :type]
          required_fields.all? { |field| core[field] }
        end

        # Extract agent capabilities summary
        #
        # @param agent_data [Hash] Full agent data structure
        # @return [Hash] Capabilities summary
        def self.extract_capabilities(agent_data)
          return {} unless agent_data

          core = agent_data[:core] || {}
          mcp = agent_data[:mcp] || {}

          {
            name: core[:name],
            tools: normalize_tools_field(core[:tools]),
            model_routing: !mcp[:model].nil?,
            security_enabled: !mcp[:security].nil?,
            context_injection: agent_data.dig(:context, :auto_inject) || false,
            mcp_enhanced: mcp_enhanced?(agent_data),
            claude_compatible: claude_compatible?(agent_data)
          }
        end

        # Transform agent metadata for specific use case
        #
        # @param agent_data [Hash] Full agent data structure
        # @param target [Symbol] Target system (:claude, :mcp, :summary)
        # @return [Hash] Transformed metadata
        def self.transform_metadata(agent_data, target)
          case target
          when :claude
            extract_claude_fields(agent_data)
          when :mcp
            extract_mcp_config(agent_data)
          when :summary
            extract_capabilities(agent_data)
          else
            agent_data
          end
        end

        class << self
          private

          # Normalize tools field to consistent array format
          def normalize_tools_field(tools)
            case tools
            when String
              [tools]
            when Array
              tools.map(&:to_s)
            when nil
              []
            else
              [tools.to_s]
            end
          end

          # Compute MCP routing information
          def compute_mcp_routing(agent_data)
            core = agent_data&.dig(:core) || {}
            agent_data&.dig(:mcp) || {}

            {
              agent_type: core[:name]&.include?("search") ? "search" : "general",
              requires_context: agent_data&.dig(:context, :auto_inject) || false,
              tool_count: normalize_tools_field(core[:tools]).length,
              complexity_score: compute_complexity_score(agent_data)
            }
          end

          # Compute complexity score for routing decisions
          def compute_complexity_score(agent_data)
            score = 0

            # Base score from tool count
            tools = normalize_tools_field(agent_data&.dig(:core, :tools))
            score += tools.length * 10

            # Additional score for complex tools
            complex_tools = %w[Grep Read WebSearch Task]
            score += (tools & complex_tools).length * 20

            # Score for MCP enhancements
            score += 30 if mcp_enhanced?(agent_data)

            case score
            when 0..50
              "simple"
            when 51..100
              "medium"
            else
              "complex"
            end
          end
        end
      end
    end
  end
end
