# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/yaml_frontmatter_parser"

module CodingAgentTools
  module Molecules
    module Agents
      # AgentParser - Molecule for parsing markdown agent files with YAML frontmatter
      #
      # Responsibilities:
      # - Parse agent markdown files with YAML frontmatter
      # - Extract and validate agent metadata
      # - Handle dual compatibility (Claude Code vs MCP proxy)
      # - Provide structured agent information
      class AgentParser
        # Result of parsing an agent file
        AgentParseResult = Struct.new(
          :success?, :agent, :error, :warnings, :raw_frontmatter, :content
        ) do
          def valid?
            success? && !agent.nil?
          end

          def claude_compatible?
            agent&.dig(:core, :name) && agent&.dig(:core, :description) && agent&.dig(:core, :tools)
          end

          def mcp_enhanced?
            agent&.dig(:mcp) && !agent[:mcp].empty?
          end
        end

        # Required core fields for all agents
        REQUIRED_CORE_FIELDS = %w[name description tools type].freeze

        # Optional core fields
        OPTIONAL_CORE_FIELDS = %w[last_modified].freeze

        # Known MCP section fields
        MCP_FIELDS = %w[model tools_mapping resources prompts security routing].freeze

        # Known context section fields
        CONTEXT_FIELDS = %w[auto_inject template cache_ttl].freeze

        # Parse agent from file path
        #
        # @param file_path [String] Path to agent markdown file
        # @return [AgentParseResult] Parse result with agent data or error
        def self.parse_file(file_path)
          return AgentParseResult.new(false, nil, "File path cannot be nil", [], nil, nil) if file_path.nil?
          return AgentParseResult.new(false, nil, "File not found: #{file_path}", [], nil, nil) unless File.exist?(file_path)

          begin
            content = File.read(file_path, encoding: "UTF-8")
            parse_content(content)
          rescue => e
            AgentParseResult.new(false, nil, "Error reading file: #{e.message}", [], nil, nil)
          end
        end

        # Parse agent from content string
        #
        # @param content [String] Agent markdown content
        # @return [AgentParseResult] Parse result with agent data or error
        def self.parse_content(content)
          return AgentParseResult.new(false, nil, "Content cannot be nil", [], nil, nil) if content.nil?

          begin
            # Parse frontmatter using existing parser
            frontmatter_result = CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser.parse(
              content, delimiter: "---", safe_mode: true
            )

            unless frontmatter_result.has_frontmatter?
              return AgentParseResult.new(false, nil, "No YAML frontmatter found", [], nil, content)
            end

            # Extract and validate agent metadata
            agent_data, warnings = extract_agent_metadata(frontmatter_result.frontmatter)
            validation_result = validate_agent_metadata(agent_data)

            if validation_result[:valid?]
              AgentParseResult.new(
                true, agent_data, nil, warnings + validation_result[:warnings],
                frontmatter_result.raw_frontmatter, frontmatter_result.content
              )
            else
              AgentParseResult.new(
                false, nil, validation_result[:errors].join("; "), warnings,
                frontmatter_result.raw_frontmatter, frontmatter_result.content
              )
            end
          rescue CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser::ParseError => e
            AgentParseResult.new(false, nil, "YAML parsing error: #{e.message}", [], nil, content)
          rescue => e
            AgentParseResult.new(false, nil, "Agent parsing error: #{e.message}", [], nil, content)
          end
        end

        # Extract agent metadata from frontmatter hash
        #
        # @param frontmatter [Hash] Parsed frontmatter
        # @return [Array<Hash, Array>] Agent data hash and warnings array
        def self.extract_agent_metadata(frontmatter)
          return [{}, ["Empty frontmatter"]] if frontmatter.nil? || frontmatter.empty?

          warnings = []
          agent_data = {
            core: {},
            mcp: {},
            context: {}
          }

          # Extract core fields (required for Claude Code compatibility)
          (REQUIRED_CORE_FIELDS + OPTIONAL_CORE_FIELDS).each do |field|
            value = frontmatter[field] || frontmatter[field.to_sym]
            agent_data[:core][field.to_sym] = value if value
          end

          # Extract MCP-specific fields (ignored by Claude Code)
          if frontmatter["mcp"] || frontmatter[:mcp]
            mcp_data = frontmatter["mcp"] || frontmatter[:mcp]
            if mcp_data.is_a?(Hash)
              agent_data[:mcp] = symbolize_keys_deep(mcp_data)
            else
              warnings << "MCP section must be a hash, got #{mcp_data.class}"
            end
          end

          # Extract context configuration
          if frontmatter["context"] || frontmatter[:context]
            context_data = frontmatter["context"] || frontmatter[:context]
            if context_data.is_a?(Hash)
              agent_data[:context] = symbolize_keys_deep(context_data)
            else
              warnings << "Context section must be a hash, got #{context_data.class}"
            end
          end

          # Check for unknown root fields
          known_fields = REQUIRED_CORE_FIELDS + OPTIONAL_CORE_FIELDS + ["mcp", "context"]
          unknown_fields = frontmatter.keys.map(&:to_s) - known_fields
          unless unknown_fields.empty?
            warnings << "Unknown root fields: #{unknown_fields.join(", ")}"
          end

          [agent_data, warnings]
        end

        # Validate agent metadata structure and required fields
        #
        # @param agent_data [Hash] Agent data to validate
        # @return [Hash] Validation result with :valid?, :errors, :warnings
        def self.validate_agent_metadata(agent_data)
          result = {
            valid?: true,
            errors: [],
            warnings: []
          }

          # Validate required core fields
          REQUIRED_CORE_FIELDS.each do |field|
            field_sym = field.to_sym
            unless agent_data.dig(:core, field_sym)
              result[:errors] << "Missing required field: #{field}"
              result[:valid?] = false
            end
          end

          # Validate tools field format
          tools = agent_data.dig(:core, :tools)
          if tools
            unless tools.is_a?(Array) || tools.is_a?(String)
              result[:errors] << "Tools field must be an array or string"
              result[:valid?] = false
            end
          end

          # Validate type field
          type_field = agent_data.dig(:core, :type)
          if type_field && type_field != "agent"
            result[:warnings] << "Type field should be 'agent', got '#{type_field}'"
          end

          # Validate MCP section if present
          if agent_data[:mcp] && !agent_data[:mcp].empty?
            validate_mcp_section(agent_data[:mcp], result)
          end

          # Validate context section if present
          if agent_data[:context] && !agent_data[:context].empty?
            validate_context_section(agent_data[:context], result)
          end

          result
        end

        # Get Claude Code compatible metadata only
        #
        # @param agent_data [Hash] Full agent data
        # @return [Hash] Claude-compatible metadata
        def self.claude_metadata(agent_data)
          return {} unless agent_data && agent_data[:core]

          # Return only core fields, ignoring MCP extensions
          agent_data[:core].dup
        end

        # Get MCP proxy specific metadata
        #
        # @param agent_data [Hash] Full agent data
        # @return [Hash] MCP-specific metadata
        def self.mcp_metadata(agent_data)
          return {} unless agent_data

          {
            core: agent_data[:core] || {},
            mcp: agent_data[:mcp] || {},
            context: agent_data[:context] || {}
          }
        end

        class << self
          private

          # Deep symbolize hash keys
          def symbolize_keys_deep(hash)
            return hash unless hash.is_a?(Hash)

            hash.each_with_object({}) do |(key, value), result|
              new_key = key.to_sym
              new_value = value.is_a?(Hash) ? symbolize_keys_deep(value) : value
              result[new_key] = new_value
            end
          end

          # Validate MCP section structure
          def validate_mcp_section(mcp_data, result)
            return unless mcp_data.is_a?(Hash)

            # Check for unknown MCP fields
            unknown_mcp_fields = mcp_data.keys.map(&:to_s) - MCP_FIELDS
            unless unknown_mcp_fields.empty?
              result[:warnings] << "Unknown MCP fields: #{unknown_mcp_fields.join(", ")}"
            end

            # Validate model field format
            if mcp_data[:model] && !mcp_data[:model].is_a?(String)
              result[:warnings] << "MCP model field should be a string"
            end

            # Validate tools_mapping structure
            if mcp_data[:tools_mapping] && !mcp_data[:tools_mapping].is_a?(Hash)
              result[:warnings] << "MCP tools_mapping should be a hash"
            end

            # Validate security section
            if mcp_data[:security] && !mcp_data[:security].is_a?(Hash)
              result[:warnings] << "MCP security section should be a hash"
            end
          end

          # Validate context section structure
          def validate_context_section(context_data, result)
            return unless context_data.is_a?(Hash)

            # Check for unknown context fields
            unknown_context_fields = context_data.keys.map(&:to_s) - CONTEXT_FIELDS
            unless unknown_context_fields.empty?
              result[:warnings] << "Unknown context fields: #{unknown_context_fields.join(", ")}"
            end

            # Validate auto_inject field
            if context_data[:auto_inject] && ![true, false].include?(context_data[:auto_inject])
              result[:warnings] << "Context auto_inject should be boolean"
            end

            # Validate template field
            if context_data[:template] && !%w[embedded external].include?(context_data[:template].to_s)
              result[:warnings] << "Context template should be 'embedded' or 'external'"
            end

            # Validate cache_ttl field
            if context_data[:cache_ttl] && !context_data[:cache_ttl].is_a?(Integer)
              result[:warnings] << "Context cache_ttl should be an integer"
            end
          end
        end
      end
    end
  end
end