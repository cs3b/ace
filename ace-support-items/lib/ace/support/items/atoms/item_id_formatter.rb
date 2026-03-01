# frozen_string_literal: true

require_relative "../models/item_id"

module Ace
  module Support
    module Items
      module Atoms
        # Splits and reconstructs 6-char b36ts IDs with type markers.
        #
        # A raw 6-char b36ts ID "8ppq7w" becomes "8pp.t.q7w" with type marker "t".
        # Subtasks append a single character: "8pp.t.q7w.a"
        #
        # @example Split a raw ID
        #   ItemIdFormatter.split("8ppq7w", type_marker: "t")
        #   # => ItemId(prefix: "8pp", type_marker: "t", suffix: "q7w")
        #
        # @example Reconstruct from formatted ID
        #   ItemIdFormatter.reconstruct("8pp.t.q7w")
        #   # => "8ppq7w"
        class ItemIdFormatter
          # Split a 6-char b36ts ID into prefix.marker.suffix format
          # @param raw_b36ts [String] 6-character b36ts ID
          # @param type_marker [String] Type marker (e.g., "t" for task, "i" for idea)
          # @return [Models::ItemId] Parsed item ID
          # @raise [ArgumentError] If raw_b36ts is not exactly 6 characters
          def self.split(raw_b36ts, type_marker:)
            raise ArgumentError, "Expected 6-char b36ts ID, got #{raw_b36ts.inspect}" unless raw_b36ts.is_a?(String) && raw_b36ts.length == 6

            Models::ItemId.new(
              raw_b36ts: raw_b36ts,
              prefix: raw_b36ts[0..2],
              type_marker: type_marker,
              suffix: raw_b36ts[3..5],
              subtask_char: nil
            )
          end

          # Create an ItemId with a subtask character
          # @param raw_b36ts [String] 6-character b36ts ID
          # @param type_marker [String] Type marker
          # @param subtask_char [String] Single subtask character (e.g., "a")
          # @return [Models::ItemId] Parsed item ID with subtask
          def self.split_subtask(raw_b36ts, type_marker:, subtask_char:)
            item_id = split(raw_b36ts, type_marker: type_marker)
            Models::ItemId.new(
              raw_b36ts: item_id.raw_b36ts,
              prefix: item_id.prefix,
              type_marker: item_id.type_marker,
              suffix: item_id.suffix,
              subtask_char: subtask_char
            )
          end

          # Reconstruct a raw 6-char b36ts ID from a formatted ID string
          # @param formatted_id [String] Formatted ID (e.g., "8pp.t.q7w" or "8pp.t.q7w.a")
          # @return [String] Raw 6-char b36ts ID (e.g., "8ppq7w")
          # @raise [ArgumentError] If format is invalid
          def self.reconstruct(formatted_id)
            match = formatted_id.match(/^([0-9a-z]{3})\.([a-z])\.([0-9a-z]{3})(?:\.([0-9a-z]))?$/)
            raise ArgumentError, "Invalid formatted ID: #{formatted_id.inspect}" unless match

            "#{match[1]}#{match[3]}"
          end

          # Build a folder name from formatted ID and slug
          # @param formatted_id [String] e.g., "8pp.t.q7w"
          # @param slug [String] e.g., "fix-login"
          # @return [String] e.g., "8pp.t.q7w-fix-login"
          def self.folder_name(formatted_id, slug)
            if slug.nil? || slug.empty?
              formatted_id
            else
              "#{formatted_id}-#{slug}"
            end
          end
        end
      end
    end
  end
end
