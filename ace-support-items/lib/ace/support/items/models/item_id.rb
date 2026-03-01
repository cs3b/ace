# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Models
        # Value object representing a parsed item ID with type marker.
        #
        # A 6-char b36ts ID (e.g., "8ppq7w") can be split into a type-marked format:
        #   prefix (3 chars) + type_marker (e.g., ".t.") + suffix (3 chars)
        #   => "8pp.t.q7w"
        #
        # Subtasks append a single char: "8pp.t.q7w.a"
        ItemId = Struct.new(
          :raw_b36ts,     # Original 6-char b36ts ID (e.g., "8ppq7w")
          :prefix,        # First 3 chars (e.g., "8pp")
          :type_marker,   # Type marker string (e.g., "t", "i")
          :suffix,        # Last 3 chars (e.g., "q7w")
          :subtask_char,  # Optional single subtask character (e.g., "a"), nil if none
          keyword_init: true
        ) do
          # Full formatted ID with type marker (e.g., "8pp.t.q7w")
          # @return [String]
          def formatted_id
            base = "#{prefix}.#{type_marker}.#{suffix}"
            subtask_char ? "#{base}.#{subtask_char}" : base
          end

          # Full formatted ID (alias for formatted_id)
          # @return [String]
          def full_id
            formatted_id
          end

          # Whether this represents a subtask
          # @return [Boolean]
          def subtask?
            !subtask_char.nil?
          end

          def to_h
            {
              raw_b36ts: raw_b36ts,
              prefix: prefix,
              type_marker: type_marker,
              suffix: suffix,
              subtask_char: subtask_char,
              formatted_id: formatted_id
            }
          end
        end
      end
    end
  end
end
