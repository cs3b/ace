# frozen_string_literal: true

require_relative "../../atoms/code/file_content_reader"
require_relative "../../atoms/context/template_parser"

module CodingAgentTools
  module Molecules
    module Context
      # AgentContextExtractor - Molecule for extracting context from agent markdown files
      #
      # Responsibilities:
      # - Read agent markdown files
      # - Parse Context Definition sections
      # - Extract YAML templates from markdown
      # - Validate and normalize extracted context
      class AgentContextExtractor
        def initialize
          @file_reader = Atoms::Code::FileContentReader.new
          @template_parser = Atoms::Context::TemplateParser.new
        end

        # Extract context template from agent markdown file
        #
        # @param agent_file_path [String] Path to agent markdown file
        # @return [Hash] {success: Boolean, template: Hash, error: String}
        def extract(agent_file_path)
          return {success: false, error: "Agent file path cannot be nil"} if agent_file_path.nil?

          # Read agent file
          file_result = @file_reader.read(agent_file_path)
          unless file_result[:success]
            return {success: false, error: "Failed to read agent file: #{file_result[:error]}"}
          end

          # Parse context from agent content
          context_result = @template_parser.parse_agent_context(file_result[:content])
          unless context_result[:success]
            return {success: false, error: "Failed to extract context from agent file: #{context_result[:error]}"}
          end

          {success: true, template: context_result[:template]}
        rescue => e
          {success: false, error: "Error extracting agent context: #{e.message}"}
        end

        # Check if agent file has valid context definition
        #
        # @param agent_file_path [String] Path to agent markdown file  
        # @return [Hash] {valid: Boolean, details: Hash, error: String}
        def validate_agent_file(agent_file_path)
          return {valid: false, error: "Agent file path cannot be nil"} if agent_file_path.nil?
          return {valid: false, error: "Agent file not found: #{agent_file_path}"} unless File.exist?(agent_file_path)

          # Read file content
          file_result = @file_reader.read(agent_file_path)
          unless file_result[:success]
            return {valid: false, error: "Cannot read agent file: #{file_result[:error]}"}
          end

          content = file_result[:content]

          # Check for Context Definition section
          has_context_section = content.match?(/^## Context Definition\s*\n/m)
          unless has_context_section
            return {
              valid: false, 
              details: {has_context_section: false},
              error: "No 'Context Definition' section found"
            }
          end

          # Check for YAML code block in context section
          context_match = content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)
          context_section = context_match[1].strip
          has_yaml_block = context_section.match?(/```(?:yaml|yml)?\s*\n.*?\n```/m)

          unless has_yaml_block
            return {
              valid: false,
              details: {has_context_section: true, has_yaml_block: false},
              error: "No YAML code block found in Context Definition section"
            }
          end

          # Try to parse the YAML
          parse_result = @template_parser.parse_agent_context(content)
          unless parse_result[:success]
            return {
              valid: false,
              details: {has_context_section: true, has_yaml_block: true, yaml_valid: false},
              error: "Invalid YAML in context definition: #{parse_result[:error]}"
            }
          end

          {
            valid: true,
            details: {
              has_context_section: true,
              has_yaml_block: true,
              yaml_valid: true,
              template: parse_result[:template]
            }
          }
        rescue => e
          {valid: false, error: "Error validating agent file: #{e.message}"}
        end

        # Extract all context-related information from agent file
        #
        # @param agent_file_path [String] Path to agent markdown file
        # @return [Hash] Comprehensive analysis of agent context
        def analyze_agent_file(agent_file_path)
          return {error: "Agent file path cannot be nil"} if agent_file_path.nil?
          return {error: "Agent file not found: #{agent_file_path}"} unless File.exist?(agent_file_path)

          file_result = @file_reader.read(agent_file_path)
          unless file_result[:success]
            return {error: "Cannot read agent file: #{file_result[:error]}"}
          end

          content = file_result[:content]
          analysis = {
            file_path: agent_file_path,
            file_size: content.bytesize,
            sections: extract_sections(content),
            context_definition: analyze_context_definition(content)
          }

          analysis
        rescue => e
          {error: "Error analyzing agent file: #{e.message}"}
        end

        private

        # Extract all sections from markdown content
        #
        # @param content [String] Markdown content
        # @return [Array<Hash>] List of sections with titles and content
        def extract_sections(content)
          sections = []
          current_section = nil

          content.lines.each do |line|
            if line.match?(/^## (.+)/)
              # Save previous section if exists
              sections << current_section if current_section

              # Start new section
              current_section = {
                title: line.match(/^## (.+)/)[1].strip,
                content: ""
              }
            elsif current_section
              current_section[:content] += line
            end
          end

          # Add last section
          sections << current_section if current_section

          sections
        end

        # Analyze Context Definition section specifically
        #
        # @param content [String] Full markdown content
        # @return [Hash] Analysis of context definition
        def analyze_context_definition(content)
          context_match = content.match(/^## Context Definition\s*\n(.*?)(?=^## |\z)/m)
          
          unless context_match
            return {present: false}
          end

          context_section = context_match[1].strip
          
          # Look for YAML blocks
          yaml_blocks = context_section.scan(/```(?:yaml|yml)?\s*\n(.*?)\n```/m)
          
          analysis = {
            present: true,
            content_length: context_section.length,
            yaml_blocks_count: yaml_blocks.length,
            yaml_blocks: []
          }

          yaml_blocks.each_with_index do |yaml_content, index|
            block_analysis = {
              index: index,
              content: yaml_content[0],
              content_length: yaml_content[0].length
            }

            # Try to parse this YAML block
            begin
              parsed = @template_parser.parse_string(yaml_content[0])
              block_analysis[:parseable] = parsed[:success]
              block_analysis[:template] = parsed[:template] if parsed[:success]
              block_analysis[:parse_error] = parsed[:error] unless parsed[:success]
            rescue => e
              block_analysis[:parseable] = false
              block_analysis[:parse_error] = e.message
            end

            analysis[:yaml_blocks] << block_analysis
          end

          analysis
        end
      end
    end
  end
end