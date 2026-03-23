# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Ace
  module Support
    module Markdown
      module Atoms
        # Pure function to extract sections from markdown using Kramdown AST
        # Supports exact string matching for section headings (v0.1.0)
        class SectionExtractor
          # Extract a section by heading text (exact string match)
          # @param content [String] The markdown content (without frontmatter)
          # @param heading_text [String] The exact heading text to match (e.g., "References")
          # @return [Hash] Result with :section_content (String), :found (Boolean), :errors (Array)
          def self.extract(content, heading_text)
            return empty_result("Empty content") if content.nil? || content.empty?
            return empty_result("Heading text required") if heading_text.nil? || heading_text.empty?

            begin
              # Parse markdown with Kramdown
              doc = Kramdown::Document.new(content, input: "GFM")

              # Find the target header in the AST
              target_header, target_index = find_header(doc.root.children, heading_text)

              unless target_header
                return {
                  section_content: nil,
                  found: false,
                  errors: ["Section not found: #{heading_text}"]
                }
              end

              # Extract content between this header and the next same-or-higher level header
              section_content = extract_section_content(
                doc.root.children,
                target_index,
                target_header.options[:level]
              )

              {
                section_content: section_content,
                found: true,
                errors: []
              }
            rescue => e
              {
                section_content: nil,
                found: false,
                errors: ["Section extraction error: #{e.message}"]
              }
            end
          end

          # Extract all sections with their headings
          # @param content [String] The markdown content
          # @return [Array<Hash>] Array of {:heading, :level, :content}
          def self.extract_all(content)
            return [] if content.nil? || content.empty?

            begin
              doc = Kramdown::Document.new(content, input: "GFM")
              headers = find_all_headers(doc.root.children)

              headers.map.with_index do |header_info, idx|
                # Extract content for each section
                content_text = extract_section_content(
                  doc.root.children,
                  header_info[:index],
                  header_info[:level]
                )

                {
                  heading: header_info[:text],
                  level: header_info[:level],
                  content: content_text
                }
              end
            rescue
              []
            end
          end

          private

          # Find a header element by exact text match
          def self.find_header(elements, heading_text)
            elements.each_with_index do |el, idx|
              next unless el.type == :header

              # Extract text from header children
              text = el.children
                .select { |c| c.type == :text }
                .map(&:value)
                .join

              return [el, idx] if text == heading_text
            end

            nil
          end

          # Find all headers in the document
          def self.find_all_headers(elements)
            headers = []

            elements.each_with_index do |el, idx|
              next unless el.type == :header

              text = el.children
                .select { |c| c.type == :text }
                .map(&:value)
                .join

              headers << {
                text: text,
                level: el.options[:level],
                index: idx
              }
            end

            headers
          end

          # Extract content elements between a header and the next same-or-higher level header
          def self.extract_section_content(elements, start_index, level)
            content_elements = []

            # Collect elements after the header until next same-or-higher level header
            ((start_index + 1)...elements.length).each do |i|
              el = elements[i]

              # Stop if we hit another header of same or higher level
              if el.type == :header && el.options[:level] <= level
                break
              end

              content_elements << el
            end

            # Convert elements back to markdown
            elements_to_markdown(content_elements)
          end

          # Convert Kramdown elements back to markdown string
          def self.elements_to_markdown(elements)
            return "" if elements.empty?

            # Create a new document with these elements
            temp_doc = Kramdown::Document.new("")
            temp_root = temp_doc.root
            temp_root.options[:encoding] = "UTF-8"

            # Add elements to the new root
            elements.each { |el| temp_root.children << el }

            # Convert to markdown
            temp_doc.to_kramdown.strip
          end

          def self.empty_result(error_message)
            {
              section_content: nil,
              found: false,
              errors: [error_message]
            }
          end
        end
      end
    end
  end
end
