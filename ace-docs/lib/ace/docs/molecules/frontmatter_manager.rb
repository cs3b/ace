# frozen_string_literal: true

require "date"
require_relative "../atoms/frontmatter_parser"

module Ace
  module Docs
    module Molecules
      # Updates document frontmatter fields
      class FrontmatterManager
        # Update frontmatter fields in a document
        # @param document [Document] Document to update
        # @param updates [Hash] Fields to update
        # @return [Boolean] true if successful
        def self.update_document(document, updates)
          return false unless document.path && File.exist?(document.path)

          # Read current content
          content = File.read(document.path)
          parsed = Atoms::FrontmatterParser.parse(content)

          # Update frontmatter
          updated_frontmatter = update_frontmatter(parsed[:frontmatter], updates)

          # Write back to file
          new_content = format_document(updated_frontmatter, parsed[:content])
          File.write(document.path, new_content)

          true
        rescue StandardError => e
          warn "Error updating #{document.path}: #{e.message}"
          false
        end

        # Update multiple documents
        # @param documents [Array<Document>] Documents to update
        # @param updates [Hash] Fields to update
        # @return [Integer] Number of successfully updated documents
        def self.update_documents(documents, updates)
          documents.count { |doc| update_document(doc, updates) }
        end

        private

        def self.update_frontmatter(frontmatter, updates)
          updated = frontmatter.dup

          updates.each do |key, value|
            # Handle nested keys with dots (e.g., "update.last-updated")
            if key.include?(".")
              parts = key.split(".")
              target = updated
              parts[0...-1].each do |part|
                target[part] ||= {}
                target = target[part]
              end
              target[parts.last] = process_value(value)
            else
              # Handle special key mappings
              case key
              when "last-updated", "last_updated"
                updated["update"] ||= {}
                updated["update"]["last-updated"] = process_value(value)
              when "last-checked", "last_checked"
                updated["update"] ||= {}
                updated["update"]["last-checked"] = process_value(value)
              when "version"
                updated["metadata"] ||= {}
                updated["metadata"]["version"] = value
              else
                updated[key] = process_value(value)
              end
            end
          end

          updated
        end

        def self.process_value(value)
          # Handle special values
          case value
          when "today", "now"
            Date.today.strftime("%Y-%m-%d")
          when /^\d{4}-\d{2}-\d{2}$/
            value  # Already a date string
          else
            value
          end
        end

        def self.format_document(frontmatter, content)
          yaml_content = frontmatter.to_yaml.strip

          # Build document with frontmatter
          [
            "---",
            yaml_content,
            "---",
            "",
            content.strip
          ].join("\n")
        end
      end
    end
  end
end