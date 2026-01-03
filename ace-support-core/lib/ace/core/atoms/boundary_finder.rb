# frozen_string_literal: true

module Ace
  module Core
    module Atoms
      # Pure functions to find semantic boundaries in XML-structured content
      # Used by ContextChunker to split content at clean boundaries
      # (between </file> and <file>, between </output> and <output>)
      #
      # ## Whitespace Handling
      #
      # Whitespace-only content between XML elements is intentionally dropped.
      # This means the sum of block line counts may be less than the total
      # content line count. This is acceptable because:
      # - The primary goal is preserving XML element integrity, not exact line counting
      # - Chunk limits are approximate; slightly exceeding is better than splitting elements
      # - Typical variance is ~2-5% of content lines
      #
      # @example Whitespace between elements
      #   content = "<file>a</file>\n\n<file>b</file>"
      #   blocks = BoundaryFinder.parse_blocks(content)
      #   # => 2 blocks (whitespace between them is dropped)
      #   # Block line sum: 2, Content lines: 3
      #
      module BoundaryFinder
        # XML element patterns for semantic blocks
        # These elements should never be split in the middle
        FILE_ELEMENT_PATTERN = %r{<file\s+[^>]*>.*?</file>}m
        OUTPUT_ELEMENT_PATTERN = %r{<output\s+[^>]*>.*?</output>}m

        module_function

        # Parse content into semantic blocks
        # Each block represents a unit that should not be split
        #
        # @param content [String] Content to parse
        # @return [Array<Hash>] Array of blocks, each with :content, :type, :lines
        #
        # @example Parse content with file elements
        #   blocks = BoundaryFinder.parse_blocks("# Header\n<file path='a.rb'>code</file>")
        #   # => [{content: "# Header\n", type: :text, lines: 1},
        #   #     {content: "<file path='a.rb'>code</file>", type: :file, lines: 1}]
        def parse_blocks(content)
          return [] if content.nil? || content.empty?

          blocks = []
          remaining = content

          while remaining && !remaining.empty?
            # Find the next XML element (file or output)
            file_match = remaining.match(FILE_ELEMENT_PATTERN)
            output_match = remaining.match(OUTPUT_ELEMENT_PATTERN)

            # Determine which comes first
            next_match = nil
            match_type = nil

            if file_match && output_match
              if file_match.begin(0) <= output_match.begin(0)
                next_match = file_match
                match_type = :file
              else
                next_match = output_match
                match_type = :output
              end
            elsif file_match
              next_match = file_match
              match_type = :file
            elsif output_match
              next_match = output_match
              match_type = :output
            end

            if next_match
              # Add text before the match as a text block (if non-whitespace)
              if next_match.begin(0) > 0
                text_content = remaining[0...next_match.begin(0)]
                # Only add text blocks with actual content (not just whitespace)
                blocks << create_block(text_content, :text) unless text_content.strip.empty?
              end

              # Add the XML element as a block
              blocks << create_block(next_match[0], match_type)

              # Move past this match
              remaining = remaining[next_match.end(0)..]
            else
              # No more XML elements, add remaining as text (if non-whitespace)
              blocks << create_block(remaining, :text) unless remaining.strip.empty?
              break
            end
          end

          blocks
        end

        # Check if content contains XML elements that require semantic chunking
        # @param content [String] Content to check
        # @return [Boolean] true if content has file or output elements
        def has_semantic_elements?(content)
          return false if content.nil? || content.empty?

          content.match?(FILE_ELEMENT_PATTERN) || content.match?(OUTPUT_ELEMENT_PATTERN)
        end

        private_class_method

        # Create a block hash
        # @param content [String] Block content
        # @param type [Symbol] Block type (:file, :output, :text)
        # @return [Hash] Block with content, type, and line count
        def create_block(content, type)
          {
            content: content,
            type: type,
            lines: content.lines.size
          }
        end
      end
    end
  end
end
