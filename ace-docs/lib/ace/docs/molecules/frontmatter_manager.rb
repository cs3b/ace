# frozen_string_literal: true

require "date"
require "time"
require "ace/support/markdown"
require_relative "../atoms/timestamp_parser"

module Ace
  module Docs
    module Molecules
      # Updates document frontmatter fields
      # Now delegates to ace-support-markdown's DocumentEditor for safe operations
      class FrontmatterManager
        # Update frontmatter fields in a document
        # @param document [Document] Document to update
        # @param updates [Hash] Fields to update
        # @return [Boolean] true if successful
        def self.update_document(document, updates)
          return false unless document.path && File.exist?(document.path)

          # Process updates to handle special values and nested keys
          processed_updates = process_updates(updates)

          # Use DocumentEditor for safe, atomic updates with backup
          editor = Ace::Support::Markdown::Organisms::DocumentEditor.new(document.path)
          editor.update_frontmatter(processed_updates)
          result = editor.save!(backup: true, validate_before: false)

          result[:success]
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

        def self.process_updates(updates)
          processed = {}

          updates.each do |key, value|
            # Handle special key mappings (convert to dot notation for DocumentEditor)
            mapped_key = case key
                        when "last-updated", "last_updated"
                          "update.last-updated"
                        when "last-checked", "last_checked"
                          "update.last-checked"
                        when "version"
                          "metadata.version"
                        else
                          key
                        end

            processed[mapped_key] = process_value(value)
          end

          processed
        end

        def self.process_value(value)
          # Handle special values
          case value
          when "today"
            Date.today.strftime("%Y-%m-%d")
          when "now"
            Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")  # ISO 8601 UTC format
          when Atoms::TimestampParser::DATE_ONLY_PATTERN
            value  # Already a date-only string
          when Atoms::TimestampParser::ISO8601_UTC_PATTERN
            value  # Already ISO 8601 UTC
          else
            value
          end
        end
      end
    end
  end
end