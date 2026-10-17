# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Truncates single-column text using the single-character ellipsis `…`.
        #
        # Each helper returns a string no wider than `width` columns (the
        # ellipsis counts as one column). Text that already fits is returned
        # unchanged. Widths below 1 render an empty string; width 1 renders
        # only the ellipsis.
        #
        # @example Branches keep both ends
        #   TextTruncator.middle("codex/ei9-campaign-composition-join", 25)
        #   # => "codex/ei9-ca…osition-join"
        module TextTruncator
          ELLIPSIS = "…"

          class << self
            # Keep the prefix and suffix; elide the middle.
            # @param text [String, nil]
            # @param width [Integer] target column width
            # @return [String]
            def middle(text, width)
              value = text.to_s
              return "" if width <= 0
              return value if value.length <= width
              return ELLIPSIS if width == 1

              remaining = width - 1
              prefix_length = (remaining + 1) / 2
              suffix_length = remaining - prefix_length
              "#{value[0, prefix_length]}#{ELLIPSIS}#{value[-suffix_length, suffix_length]}"
            end

            # Keep the prefix; truncate the tail.
            # @param text [String, nil]
            # @param width [Integer] target column width
            # @return [String]
            def right(text, width)
              value = text.to_s
              return "" if width <= 0
              return value if value.length <= width
              return ELLIPSIS if width == 1

              "#{value[0, width - 1]}#{ELLIPSIS}"
            end

            # Keep the suffix; elide the head.
            # @param text [String, nil]
            # @param width [Integer] target column width
            # @return [String]
            def left(text, width)
              value = text.to_s
              return "" if width <= 0
              return value if value.length <= width
              return ELLIPSIS if width == 1

              "#{ELLIPSIS}#{value[-(width - 1), width - 1]}"
            end
          end
        end
      end
    end
  end
end
