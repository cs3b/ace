# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Molecules
        # Build markdown documents programmatically
        # Provides fluent API for creating documents from scratch
        class DocumentBuilder
          attr_reader :frontmatter, :sections

          def initialize
            @frontmatter = {}
            @sections = []
          end

          # Set frontmatter fields
          # @param data [Hash] Frontmatter data
          # @return [DocumentBuilder] self for chaining
          def frontmatter(data)
            raise ArgumentError, "Frontmatter must be a hash" unless data.is_a?(Hash)

            @frontmatter = @frontmatter.merge(data)
            self
          end

          # Set a single frontmatter field
          # @param key [String, Symbol] The field key
          # @param value [Object] The field value
          # @return [DocumentBuilder] self for chaining
          def set_field(key, value)
            @frontmatter[key.to_s] = value
            self
          end

          # Add a section
          # @param heading [String] The section heading
          # @param content [String] The section content
          # @param level [Integer] The heading level (default: 2)
          # @return [DocumentBuilder] self for chaining
          def add_section(heading:, content:, level: 2)
            section = Models::Section.new(
              heading: heading,
              level: level,
              content: content
            )

            @sections << section
            self
          end

          # Add a title (level 1 heading)
          # @param title [String] The title text
          # @param content [String] Content under the title
          # @return [DocumentBuilder] self for chaining
          def title(title, content: "")
            add_section(heading: title, content: content, level: 1)
          end

          # Add raw body content (without sections)
          # @param content [String] The body content
          # @return [DocumentBuilder] self for chaining
          def body(content)
            @body_content = content
            self
          end

          # Build the document as a MarkdownDocument model
          # @return [MarkdownDocument]
          def build
            body_text = if @sections.any?
              # Build from sections
              @sections.map(&:to_markdown).join("\n\n")
            else
              # Use raw body content
              @body_content || ""
            end

            Models::MarkdownDocument.new(
              frontmatter: @frontmatter,
              raw_body: body_text,
              sections: @sections.any? ? @sections : nil
            )
          end

          # Build and convert to markdown string
          # @return [String]
          def to_markdown
            build.to_markdown
          end

          # Validate the current builder state
          # @return [Hash] Result with :valid, :errors
          def validate
            errors = []

            if @frontmatter.empty?
              errors << "No frontmatter defined"
            end

            if @sections.empty? && (@body_content.nil? || @body_content.empty?)
              errors << "No content defined (neither sections nor body)"
            end

            {
              valid: errors.empty?,
              errors: errors
            }
          end

          # Check if builder is valid
          # @return [Boolean]
          def valid?
            validate[:valid]
          end

          # Create a builder from an existing document
          # @param document [MarkdownDocument] The source document
          # @return [DocumentBuilder]
          def self.from_document(document)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)

            builder = new
            builder.frontmatter(document.frontmatter)

            if document.has_sections?
              document.sections.each do |section|
                builder.add_section(
                  heading: section.heading,
                  content: section.content,
                  level: section.level
                )
              end
            else
              builder.body(document.raw_body)
            end

            builder
          end

          # Create a minimal document with just frontmatter
          # @param frontmatter [Hash] The frontmatter data
          # @return [MarkdownDocument]
          def self.minimal(frontmatter)
            new.frontmatter(frontmatter).build
          end
        end
      end
    end
  end
end
