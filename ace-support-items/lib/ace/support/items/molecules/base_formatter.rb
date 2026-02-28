# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Minimal default formatter for item display.
        # Gems can override with their own formatter for richer output.
        class BaseFormatter
          # Format a single item for display
          # @param item [Object] Item with id/title (LoadedDocument, ScanResult, etc.)
          # @param scan_result [ScanResult, nil] Optional scan result for ID fallback
          # @return [String] Formatted line
          def self.format_item(item, scan_result: nil)
            id = resolve_id(item, scan_result)
            title = resolve_title(item)

            "#{id} #{title}"
          end

          # Format a list of items
          # @param items [Array] Items to format
          # @return [String] Formatted list
          def self.format_list(items)
            return "No items found." if items.nil? || items.empty?

            items.map { |item| format_item(item) }.join("\n")
          end

          private_class_method def self.resolve_id(item, scan_result)
            return scan_result.id if scan_result&.id
            return item.frontmatter["id"] if item.respond_to?(:frontmatter) && item.frontmatter.is_a?(Hash)
            return item[:id] || item["id"] if item.respond_to?(:[])
            return item.id if item.respond_to?(:id)
            "?"
          rescue
            "?"
          end

          private_class_method def self.resolve_title(item)
            return item.title if item.respond_to?(:title) && item.title
            return item[:title] || item["title"] if item.respond_to?(:[])
            "Untitled"
          rescue
            "Untitled"
          end
        end
      end
    end
  end
end
