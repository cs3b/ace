# frozen_string_literal: true

require_relative "../atoms/context/template_parser"
require_relative "../molecules/context/context_aggregator"
require_relative "../molecules/context/output_formatter"
require_relative "../molecules/context/agent_context_extractor"

module CodingAgentTools
  module Organisms
    # ContextLoader - Organism for orchestrating context loading workflow
    #
    # Responsibilities:
    # - Orchestrate template parsing from various sources
    # - Coordinate file reading and command execution
    # - Manage caching of context results
    # - Provide unified interface for context loading operations
    class ContextLoader
      def initialize(options = {})
        @template_parser = Atoms::Context::TemplateParser.new
        @context_aggregator = Molecules::Context::ContextAggregator.new(options)
        @agent_extractor = Molecules::Context::AgentContextExtractor.new
        @options = options
      end

      # Load context from template data
      #
      # @param template_data [Hash] Template source info {type:, source:}
      # @param options [Hash] Loading options (max_size, timeout, etc.)
      # @return [Hash] Context result with files, commands, and metadata
      def load_from_template(template_data, options = {})
        # Parse template based on source type
        template_result = parse_template_source(template_data)
        unless template_result[:success]
          return {
            success: false,
            error: template_result[:error],
            files: [],
            commands: [],
            errors: [template_result[:error]]
          }
        end

        template = template_result[:template]

        # Aggregate context from template
        start_time = Time.now
        context_result = @context_aggregator.aggregate(template)
        processing_time = Time.now - start_time

        # Add metadata
        context_result.merge(
          success: true,
          template_source: template_data,
          template: template,
          processing_time: processing_time,
          total_files: context_result[:files].length,
          total_commands: context_result[:commands].length,
          total_errors: context_result[:errors].length,
          total_size: calculate_total_size(context_result)
        )
      rescue => e
        {
          success: false,
          error: "Context loading failed: #{e.message}",
          files: [],
          commands: [],
          errors: ["Context loading failed: #{e.message}"]
        }
      end

      # Validate template source without processing
      #
      # @param template_data [Hash] Template source info {type:, source:}
      # @return [Hash] Validation result
      def validate_template_source(template_data)
        parse_result = parse_template_source(template_data)
        
        if parse_result[:success]
          template = parse_result[:template]
          {
            valid: true,
            template: template,
            files_count: template[:files].length,
            commands_count: template[:commands].length,
            format_hint: template[:format]
          }
        else
          {
            valid: false,
            error: parse_result[:error]
          }
        end
      rescue => e
        {
          valid: false,
          error: "Template validation failed: #{e.message}"
        }
      end

      # Get context summary for display
      #
      # @param context_result [Hash] Result from load_from_template
      # @return [String] Human-readable summary
      def get_context_summary(context_result)
        return "Context loading failed: #{context_result[:error]}" unless context_result[:success]

        lines = []
        lines << "Context loaded successfully:"
        lines << "  Files: #{context_result[:total_files]} (#{format_size(context_result[:total_size])})"
        lines << "  Commands: #{context_result[:total_commands]}"
        lines << "  Processing time: #{format_time(context_result[:processing_time])}"
        
        if context_result[:total_errors] > 0
          lines << "  Errors: #{context_result[:total_errors]}"
        end

        # Show file breakdown
        if context_result[:files].any?
          lines << "  File details:"
          context_result[:files].each do |file|
            lines << "    - #{file[:path]} (#{format_size(file[:size])})"
          end
        end

        # Show command breakdown
        if context_result[:commands].any?
          lines << "  Command details:"
          context_result[:commands].each do |cmd|
            status = cmd[:success] ? "✓" : "✗"
            lines << "    #{status} #{cmd[:command]}"
          end
        end

        lines.join("\n")
      end

      # Check agent file for context definition
      #
      # @param agent_file_path [String] Path to agent markdown file
      # @return [Hash] Validation result for agent file
      def validate_agent_file(agent_file_path)
        @agent_extractor.validate_agent_file(agent_file_path)
      end

      # Analyze agent file comprehensively
      #
      # @param agent_file_path [String] Path to agent markdown file
      # @return [Hash] Comprehensive analysis of agent file
      def analyze_agent_file(agent_file_path)
        @agent_extractor.analyze_agent_file(agent_file_path)
      end

      private

      # Parse template from various source types
      #
      # @param template_data [Hash] Template source info {type:, source:}
      # @return [Hash] Parse result {success:, template:, error:}
      def parse_template_source(template_data)
        case template_data[:type]
        when :yaml_file
          @template_parser.parse_file(template_data[:source])
        when :yaml_string
          @template_parser.parse_string(template_data[:source])
        when :agent_file
          @agent_extractor.extract(template_data[:source])
        else
          {success: false, error: "Unknown template source type: #{template_data[:type]}"}
        end
      end

      # Calculate total size of all content
      #
      # @param context_result [Hash] Context aggregation result
      # @return [Integer] Total size in bytes
      def calculate_total_size(context_result)
        file_size = context_result[:files].sum { |file| file[:size] }
        command_size = context_result[:commands].sum { |cmd| (cmd[:output] || "").bytesize }
        file_size + command_size
      end

      # Format size for display
      #
      # @param bytes [Integer] Size in bytes
      # @return [String] Formatted size
      def format_size(bytes)
        if bytes < 1024
          "#{bytes} bytes"
        elsif bytes < 1024 * 1024
          "#{(bytes / 1024.0).round(1)} KB"
        else
          "#{(bytes / (1024.0 * 1024)).round(1)} MB"
        end
      end

      # Format time for display
      #
      # @param seconds [Float] Time in seconds
      # @return [String] Formatted time
      def format_time(seconds)
        if seconds < 1
          "#{(seconds * 1000).round(0)}ms"
        else
          "#{seconds.round(2)}s"
        end
      end
    end
  end
end