# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Molecules
        # Edit document sections by heading
        # Supports replace, append, delete operations using exact string matching
        class SectionEditor
          # Replace a section's content by heading
          # @param document [MarkdownDocument] The document to update
          # @param heading [String] The exact heading text to match
          # @param new_content [String] The replacement content
          # @return [MarkdownDocument] New document with replaced section
          def self.replace_section(document, heading, new_content)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)

            # Extract the current section to get its level
            section_result = Atoms::SectionExtractor.extract(document.raw_body, heading)

            unless section_result[:found]
              raise SectionNotFoundError, "Section not found: #{heading}"
            end

            # Parse all sections
            all_sections = Atoms::SectionExtractor.extract_all(document.raw_body)

            # Find and replace the target section
            new_sections = all_sections.map do |s|
              if s[:heading] == heading
                Models::Section.new(
                  heading: s[:heading],
                  level: s[:level],
                  content: new_content
                )
              else
                Models::Section.new(
                  heading: s[:heading],
                  level: s[:level],
                  content: s[:content] || ""
                )
              end
            end

            document.with_sections(new_sections)
          end

          # Append content to a section
          # @param document [MarkdownDocument] The document to update
          # @param heading [String] The exact heading text to match
          # @param additional_content [String] Content to append
          # @return [MarkdownDocument] New document with updated section
          def self.append_to_section(document, heading, additional_content)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)

            # Extract current section
            section_result = Atoms::SectionExtractor.extract(document.raw_body, heading)

            unless section_result[:found]
              raise SectionNotFoundError, "Section not found: #{heading}"
            end

            # Combine existing and new content
            existing_content = section_result[:section_content] || ""
            separator = existing_content.empty? ? "" : "\n\n"
            new_content = "#{existing_content}#{separator}#{additional_content}"

            # Replace with combined content
            replace_section(document, heading, new_content)
          end

          # Delete a section
          # @param document [MarkdownDocument] The document to update
          # @param heading [String] The exact heading text to match
          # @return [MarkdownDocument] New document without the section
          def self.delete_section(document, heading)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)

            # Parse all sections
            all_sections = Atoms::SectionExtractor.extract_all(document.raw_body)

            # Filter out the target section
            remaining_sections = all_sections.reject { |s| s[:heading] == heading }

            # Convert to Section models
            new_sections = remaining_sections.map do |s|
              Models::Section.new(
                heading: s[:heading],
                level: s[:level],
                content: s[:content] || ""
              )
            end

            document.with_sections(new_sections)
          end

          # Insert a new section before another section
          # @param document [MarkdownDocument] The document to update
          # @param before_heading [String] Insert before this heading
          # @param new_section [Section] The section to insert
          # @return [MarkdownDocument] New document with inserted section
          def self.insert_section_before(document, before_heading, new_section)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)
            raise ArgumentError, "New section must be a Section" unless new_section.is_a?(Models::Section)

            # Parse all sections
            all_sections = Atoms::SectionExtractor.extract_all(document.raw_body)

            # Find insertion point
            insert_index = all_sections.find_index { |s| s[:heading] == before_heading }

            raise SectionNotFoundError, "Section not found: #{before_heading}" unless insert_index

            # Convert existing sections to models
            sections = all_sections.map do |s|
              Models::Section.new(
                heading: s[:heading],
                level: s[:level],
                content: s[:content] || ""
              )
            end

            # Insert new section
            sections.insert(insert_index, new_section)

            document.with_sections(sections)
          end

          # Add a new section at the end
          # @param document [MarkdownDocument] The document to update
          # @param new_section [Section] The section to add
          # @return [MarkdownDocument] New document with added section
          def self.add_section(document, new_section)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)
            raise ArgumentError, "New section must be a Section" unless new_section.is_a?(Models::Section)

            # Parse all sections
            all_sections = Atoms::SectionExtractor.extract_all(document.raw_body)

            # Convert to models
            sections = all_sections.map do |s|
              Models::Section.new(
                heading: s[:heading],
                level: s[:level],
                content: s[:content] || ""
              )
            end

            # Add new section
            sections << new_section

            document.with_sections(sections)
          end
        end
      end
    end
  end
end
