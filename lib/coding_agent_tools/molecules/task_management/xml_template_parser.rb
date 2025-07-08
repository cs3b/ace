# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module TaskManagement
      # XmlTemplateParser is a molecule that parses XML-embedded template content
      # from markdown files, supporting multiple XML formats (templates, documents, guides)
      # with an extensible architecture for future format additions.
      class XmlTemplateParser
        # Parsed document structure
        ParsedDocument = Struct.new(:path, :content, :type, :source_format, :line_start, :line_end) do
          def template?
            type == :template
          end

          def guide?
            type == :guide
          end
        end

        # Parser result containing all extracted documents
        ParserResult = Struct.new(:documents, :errors, :warnings) do
          def success?
            errors.empty?
          end

          def has_warnings?
            !warnings.empty?
          end

          def template_count
            documents.count(&:template?)
          end

          def guide_count
            documents.count(&:guide?)
          end
        end

        # Default format handlers registry (initialized after class definitions)
        def self.default_formats
          @default_formats ||= {
            documents: DocumentsFormatHandler.new,
            templates: TemplatesFormatHandler.new
          }.freeze
        end

        # @param format_handlers [Hash] Custom format handlers (optional)
        def initialize(format_handlers: {})
          @format_handlers = self.class.default_formats.merge(format_handlers)
          @errors = []
          @warnings = []
        end

        # Parse XML-embedded content from markdown text
        # @param content [String] Markdown content to parse
        # @param source_file [String] Source file path for error reporting
        # @return [ParserResult] Parsing results with documents, errors, and warnings
        def parse(content, source_file: nil)
          reset_state
          documents = []

          @format_handlers.each do |format_name, handler|
            extracted = handler.extract(content, source_file)
            documents.concat(extracted.documents)
            @errors.concat(extracted.errors)
            @warnings.concat(extracted.warnings)
          rescue => e
            @errors << "Error parsing #{format_name} format: #{e.message}"
          end

          ParserResult.new(documents, @errors, @warnings)
        end

        # Register a new format handler
        # @param format_name [Symbol] Name of the format
        # @param handler [Object] Format handler implementing extract method
        def register_format(format_name, handler)
          @format_handlers[format_name] = handler
        end

        # Check if a format is supported
        # @param format_name [Symbol] Format name to check
        # @return [Boolean] True if format is supported
        def supports_format?(format_name)
          @format_handlers.key?(format_name)
        end

        # Get list of supported formats
        # @return [Array<Symbol>] List of supported format names
        def supported_formats
          @format_handlers.keys
        end

        private

        attr_reader :format_handlers

        def reset_state
          @errors = []
          @warnings = []
        end

        # Format handler for <documents> XML sections
        class DocumentsFormatHandler
          SECTION_PATTERN = /<documents>(.*?)<\/documents>/m
          TEMPLATE_PATTERN = /<template\s+path="([^"]+)">(.*?)<\/template>/m
          GUIDE_PATTERN = /<guide\s+path="([^"]+)">(.*?)<\/guide>/m

          def extract(content, source_file)
            documents = []
            errors = []
            warnings = []

            content.scan(SECTION_PATTERN) do |section_match|
              section_content = section_match[0]
              line_start = find_line_number(content, $~.begin(0))

              # Extract templates
              section_content.scan(TEMPLATE_PATTERN) do |path, template_content|
                documents << ParsedDocument.new(
                  path.strip,
                  template_content,
                  :template,
                  :documents,
                  line_start,
                  find_line_number(content, $~.end(0))
                )
              end

              # Extract guides
              section_content.scan(GUIDE_PATTERN) do |path, guide_content|
                documents << ParsedDocument.new(
                  path.strip,
                  guide_content,
                  :guide,
                  :documents,
                  line_start,
                  find_line_number(content, $~.end(0))
                )
              end
            end

            FormatResult.new(documents, errors, warnings)
          end

          private

          def find_line_number(content, position)
            content[0...position].count("\n") + 1
          end
        end

        # Format handler for legacy <templates> XML sections
        class TemplatesFormatHandler
          SECTION_PATTERN = /<templates>(.*?)<\/templates>/m
          TEMPLATE_PATTERN = /<template\s+path="([^"]+)">(.*?)<\/template>/m

          def extract(content, source_file)
            documents = []
            errors = []
            warnings = []

            content.scan(SECTION_PATTERN) do |section_match|
              section_content = section_match[0]
              line_start = find_line_number(content, $~.begin(0))

              # Extract templates
              section_content.scan(TEMPLATE_PATTERN) do |path, template_content|
                documents << ParsedDocument.new(
                  path.strip,
                  template_content,
                  :template,
                  :templates,
                  line_start,
                  find_line_number(content, $~.end(0))
                )
              end

              # Add warning for legacy format usage
              warnings << "Legacy <templates> format detected, consider migrating to <documents> format"
            end

            FormatResult.new(documents, errors, warnings)
          end

          private

          def find_line_number(content, position)
            content[0...position].count("\n") + 1
          end
        end

        # Result structure for format handlers
        FormatResult = Struct.new(:documents, :errors, :warnings)
      end
    end
  end
end
