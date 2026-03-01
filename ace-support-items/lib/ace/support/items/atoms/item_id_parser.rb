# frozen_string_literal: true

require_relative "../models/item_id"

module Ace
  module Support
    module Items
      module Atoms
        # Parses various reference forms into an ItemId model.
        #
        # Supported formats:
        #   - Full:    "8pp.t.q7w"    → prefix=8pp, marker=t, suffix=q7w
        #   - Short:   "t.q7w"        → prefix=nil, marker=t, suffix=q7w
        #   - Suffix:  "q7w"          → prefix=nil, marker=nil, suffix=q7w
        #   - Subtask: "8pp.t.q7w.a"  → prefix=8pp, marker=t, suffix=q7w, subtask=a
        #   - Raw:     "8ppq7w"       → prefix=8pp, marker=nil, suffix=q7w (6-char raw b36ts)
        class ItemIdParser
          # Full format: prefix.marker.suffix (e.g., "8pp.t.q7w")
          FULL_PATTERN = /^([0-9a-z]{3})\.([a-z])\.([0-9a-z]{3})$/

          # Full with subtask: prefix.marker.suffix.subtask (e.g., "8pp.t.q7w.a")
          SUBTASK_PATTERN = /^([0-9a-z]{3})\.([a-z])\.([0-9a-z]{3})\.([0-9a-z])$/

          # Short format: marker.suffix (e.g., "t.q7w")
          SHORT_PATTERN = /^([a-z])\.([0-9a-z]{3})$/

          # Suffix-only: 3 chars (e.g., "q7w")
          SUFFIX_PATTERN = /^[0-9a-z]{3}$/

          # Raw 6-char b36ts (e.g., "8ppq7w")
          RAW_PATTERN = /^[0-9a-z]{6}$/

          # Parse a reference string into an ItemId
          # @param ref [String] Reference in any supported format
          # @param default_marker [String, nil] Default type marker for ambiguous refs
          # @return [ItemId, nil] Parsed item ID or nil if unparseable
          def self.parse(ref, default_marker: nil)
            return nil if ref.nil? || ref.empty?

            ref = ref.strip.downcase

            # Try each pattern in order of specificity
            if (match = ref.match(SUBTASK_PATTERN))
              Models::ItemId.new(
                raw_b36ts: "#{match[1]}#{match[3]}",
                prefix: match[1],
                type_marker: match[2],
                suffix: match[3],
                subtask_char: match[4]
              )
            elsif (match = ref.match(FULL_PATTERN))
              Models::ItemId.new(
                raw_b36ts: "#{match[1]}#{match[3]}",
                prefix: match[1],
                type_marker: match[2],
                suffix: match[3],
                subtask_char: nil
              )
            elsif (match = ref.match(SHORT_PATTERN))
              Models::ItemId.new(
                raw_b36ts: nil,
                prefix: nil,
                type_marker: match[1],
                suffix: match[2],
                subtask_char: nil
              )
            elsif ref.match?(SUFFIX_PATTERN)
              Models::ItemId.new(
                raw_b36ts: nil,
                prefix: nil,
                type_marker: default_marker,
                suffix: ref,
                subtask_char: nil
              )
            elsif ref.match?(RAW_PATTERN)
              Models::ItemId.new(
                raw_b36ts: ref,
                prefix: ref[0..2],
                type_marker: default_marker,
                suffix: ref[3..5],
                subtask_char: nil
              )
            end
          end
        end
      end
    end
  end
end
