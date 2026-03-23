# frozen_string_literal: true

require "date"

module Ace
  module Support
    module Markdown
      module Molecules
        # Atomic frontmatter field updates for markdown documents
        # Handles nested keys, special values, and immutable transformations
        class FrontmatterEditor
          # Update frontmatter fields in a document
          # @param document [MarkdownDocument] The document to update
          # @param updates [Hash] Fields to update (supports nested keys with dots)
          # @return [MarkdownDocument] New document with updated frontmatter
          def self.update(document, updates)
            raise ArgumentError, "Document must be a MarkdownDocument" unless document.is_a?(Models::MarkdownDocument)
            raise ArgumentError, "Updates must be a hash" unless updates.is_a?(Hash)

            updated_frontmatter = apply_updates(document.frontmatter.dup, updates)

            document.with_frontmatter(updated_frontmatter)
          end

          # Update a single field
          # @param document [MarkdownDocument] The document to update
          # @param key [String] The field key (supports dots for nesting)
          # @param value [Object] The new value
          # @return [MarkdownDocument] New document with updated field
          def self.update_field(document, key, value)
            update(document, {key => value})
          end

          # Delete a field from frontmatter
          # @param document [MarkdownDocument] The document to update
          # @param key [String] The field key to delete
          # @return [MarkdownDocument] New document with field removed
          def self.delete_field(document, key)
            updated_frontmatter = document.frontmatter.dup
            updated_frontmatter.delete(key)
            updated_frontmatter.delete(key.to_sym) if key.is_a?(String)

            document.with_frontmatter(updated_frontmatter)
          end

          # Merge multiple updates atomically
          # @param document [MarkdownDocument] The document to update
          # @param updates_list [Array<Hash>] List of update hashes
          # @return [MarkdownDocument] New document with all updates applied
          def self.merge_updates(document, updates_list)
            raise ArgumentError, "Updates list must be an array" unless updates_list.is_a?(Array)

            updates_list.reduce(document) do |doc, updates|
              update(doc, updates)
            end
          end

          private

          # Apply updates to frontmatter hash (mutable operation on copy)
          def self.apply_updates(frontmatter, updates)
            updates.each do |key, value|
              key_str = key.to_s

              # Handle nested keys with dots (e.g., "update.last-updated")
              if key_str.include?(".")
                apply_nested_update(frontmatter, key_str, value)
              else
                frontmatter[key_str] = process_value(value)
              end
            end

            frontmatter
          end

          # Apply update to nested key path
          def self.apply_nested_update(frontmatter, key_path, value)
            parts = key_path.split(".")
            target = frontmatter

            # Navigate to the target hash
            parts[0...-1].each do |part|
              target[part] ||= {}
              target = target[part]
            end

            # Set the final value
            target[parts.last] = process_value(value)
          end

          # Process special values before setting
          def self.process_value(value)
            case value
            when "today"
              Date.today.strftime("%Y-%m-%d")
            when "now"
              Time.now.strftime("%Y-%m-%d %H:%M:%S")
            when /^\d{4}-\d{2}-\d{2}$/
              value # Already a date string
            else
              value
            end
          end
        end
      end
    end
  end
end
