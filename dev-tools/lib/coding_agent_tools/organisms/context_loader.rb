# frozen_string_literal: true

require_relative "../atoms/context/template_parser"
require_relative "../molecules/context/context_aggregator"
require_relative "../molecules/context/output_formatter"
require_relative "../molecules/context/agent_context_extractor"
require_relative "../molecules/context/input_format_detector"
require_relative "../molecules/context/markdown_yaml_extractor"
require_relative "../molecules/context/document_embedder"

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
        @format_detector = Molecules::Context::InputFormatDetector.new
        @markdown_extractor = Molecules::Context::MarkdownYamlExtractor.new
        @document_embedder = Molecules::Context::DocumentEmbedder.new
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

      # Load context with auto-format detection and optional embedding
      #
      # @param input [String] File path or string content
      # @param options [Hash] Loading and embedding options
      # @return [Hash] Context result with possible document embedding
      def load_with_auto_detection(input, options = {})
        # Detect format
        detection_result = @format_detector.detect_format(input)
        unless detection_result[:success]
          return {
            success: false,
            error: detection_result[:error],
            files: [],
            commands: [],
            errors: [detection_result[:error]]
          }
        end

        # Prepare template data based on detection
        if detection_result[:file_path]
          template_data = {type: detection_result[:format], source: detection_result[:file_path]}
          source_document = File.read(detection_result[:file_path]) if File.exist?(detection_result[:file_path])
        else
          template_data = {type: detection_result[:format], source: detection_result[:content]}
          source_document = detection_result[:content]
        end

        # Load context using standard process
        context_result = load_from_template(template_data, options)
        return context_result unless context_result[:success]

        # Check if embedding is requested
        embedding_options = options.merge(
          yaml_config: context_result[:template]
        )

        if source_document && @document_embedder.should_embed?(embedding_options)
          # Format the context result for embedding
          formatter = Molecules::Context::OutputFormatter.new(options[:format] || "markdown-xml")
          formatted_output = formatter.format(context_result)

          # Embed into source document
          embedding_result = @document_embedder.embed_content(
            source_document,
            formatted_output,
            embedding_options
          )

          if embedding_result[:success]
            # Replace the context result content with embedded version
            context_result.merge(
              embedded_content: embedding_result[:content],
              embedding_applied: true,
              embedding_strategy: embedding_result[:strategy],
              original_content: formatted_output
            )
          else
            # If embedding fails, return original context with error note
            context_result.merge(
              embedding_error: embedding_result[:error],
              embedding_applied: false
            )
          end
        else
          # No embedding requested or no source document
          context_result.merge(embedding_applied: false)
        end
      rescue => e
        {
          success: false,
          error: "Auto-detection context loading failed: #{e.message}",
          files: [],
          commands: [],
          errors: ["Auto-detection context loading failed: #{e.message}"]
        }
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
        when :markdown_file
          # New: Handle markdown files with <context-tool-config> tags
          content = File.read(template_data[:source])
          @markdown_extractor.extract_yaml_from_markdown(content)
        when :markdown_string
          # New: Handle markdown strings with <context-tool-config> tags
          @markdown_extractor.extract_yaml_from_markdown(template_data[:source])
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
