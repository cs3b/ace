# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Models
        # Immutable representation of a markdown document
        # Contains frontmatter and sections for safe transformations
        class MarkdownDocument
          attr_reader :frontmatter, :sections, :raw_body, :file_path

          # Create a new MarkdownDocument
          # @param frontmatter [Hash] The YAML frontmatter data
          # @param raw_body [String] The raw body content (without frontmatter)
          # @param sections [Array<Section>] Optional parsed sections
          # @param file_path [String, nil] Optional source file path
          def initialize(frontmatter:, raw_body:, sections: nil, file_path: nil)
            @frontmatter = frontmatter.freeze
            @raw_body = raw_body.freeze
            @sections = sections&.freeze
            @file_path = file_path&.freeze

            validate!
          end

          # Create a new document with updated frontmatter
          # @param updates [Hash] Frontmatter updates to merge
          # @return [MarkdownDocument] New document instance
          def with_frontmatter(updates)
            new_frontmatter = @frontmatter.merge(updates)

            MarkdownDocument.new(
              frontmatter: new_frontmatter,
              raw_body: @raw_body,
              sections: @sections,
              file_path: @file_path
            )
          end

          # Create a new document with updated body
          # @param new_body [String] The new body content
          # @return [MarkdownDocument] New document instance
          def with_body(new_body)
            MarkdownDocument.new(
              frontmatter: @frontmatter,
              raw_body: new_body,
              sections: nil, # Invalidate sections cache
              file_path: @file_path
            )
          end

          # Create a new document with updated sections
          # @param new_sections [Array<Section>] The new sections
          # @return [MarkdownDocument] New document instance
          def with_sections(new_sections)
            # Rebuild raw_body from sections
            new_body = new_sections.map(&:to_markdown).join("\n\n")

            MarkdownDocument.new(
              frontmatter: @frontmatter,
              raw_body: new_body,
              sections: new_sections,
              file_path: @file_path
            )
          end

          # Get a specific frontmatter field
          # @param key [String, Symbol] The field key
          # @return [Object, nil] The field value
          def get_frontmatter(key)
            @frontmatter[key.to_s] || @frontmatter[key.to_sym]
          end

          # Find a section by heading text
          # @param heading [String] The heading to find
          # @return [Section, nil]
          def find_section(heading)
            return nil unless @sections

            @sections.find { |s| s.heading == heading }
          end

          # Convert document to complete markdown string
          # @return [String] The complete markdown document
          def to_markdown
            Atoms::FrontmatterSerializer.rebuild_document(@frontmatter, @raw_body)
          end

          # Check if document has frontmatter
          # @return [Boolean]
          def has_frontmatter?
            !@frontmatter.empty?
          end

          # Check if document has sections parsed
          # @return [Boolean]
          def has_sections?
            !@sections.nil? && !@sections.empty?
          end

          # Get document statistics
          # @return [Hash]
          def stats
            {
              frontmatter_fields: @frontmatter.keys.length,
              body_length: @raw_body.length,
              sections_count: @sections&.length || 0,
              word_count: @raw_body.split(/\s+/).length
            }
          end

          # Compare documents for equality
          # @param other [MarkdownDocument]
          # @return [Boolean]
          def ==(other)
            other.is_a?(MarkdownDocument) &&
              @frontmatter == other.frontmatter &&
              @raw_body == other.raw_body
          end

          # Hash representation
          # @return [Hash]
          def to_h
            {
              frontmatter: @frontmatter,
              raw_body: @raw_body,
              sections: @sections&.map(&:to_h),
              file_path: @file_path,
              stats: stats
            }
          end

          # Parse document from markdown string
          # @param content [String] The complete markdown content
          # @param file_path [String, nil] Optional source file path
          # @return [MarkdownDocument]
          def self.parse(content, file_path: nil)
            result = Atoms::FrontmatterExtractor.extract(content)

            raise ValidationError, result[:errors].join(", ") unless result[:valid]

            new(
              frontmatter: result[:frontmatter],
              raw_body: result[:body],
              file_path: file_path
            )
          end

          # Parse document with sections
          # @param content [String] The complete markdown content
          # @param file_path [String, nil] Optional source file path
          # @return [MarkdownDocument]
          def self.parse_with_sections(content, file_path: nil)
            doc = parse(content, file_path: file_path)

            # Extract all sections
            section_data = Atoms::SectionExtractor.extract_all(doc.raw_body)

            sections = section_data.map do |s|
              Section.new(
                heading: s[:heading],
                level: s[:level],
                content: s[:content] || ""
              )
            end

            doc.with_sections(sections)
          end

          private

          def validate!
            raise ArgumentError, "Frontmatter must be a hash" unless @frontmatter.is_a?(Hash)
            raise ArgumentError, "Raw body cannot be nil" if @raw_body.nil?

            if @sections
              raise ArgumentError, "Sections must be an array" unless @sections.is_a?(Array)
              unless @sections.all? { |s| s.is_a?(Section) }
                raise ArgumentError, "All sections must be Section instances"
              end
            end
          end
        end
      end
    end
  end
end
