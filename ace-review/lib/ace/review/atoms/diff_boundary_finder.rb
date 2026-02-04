# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure function for parsing unified diffs into file blocks
      #
      # Parses `diff --git` format diffs and extracts individual file blocks
      # with their paths and content. Used by the chunked strategy to split
      # large diffs at file boundaries.
      #
      # Thread-safe: This module uses only class methods with no mutable
      # instance state. All methods are pure functions that can be safely
      # called concurrently from multiple threads.
      #
      # @example Basic usage
      #   blocks = DiffBoundaryFinder.parse(diff_text)
      #   #=> [
      #   #     { path: "lib/foo.rb", content: "diff --git...", lines: 45, change_type: :modified },
      #   #     { path: "test/foo_test.rb", content: "diff --git...", lines: 30, change_type: :modified }
      #   #   ]
      module DiffBoundaryFinder
        # Pattern to match the start of a file diff block
        # Matches: diff --git a/path/to/file b/path/to/file
        DIFF_HEADER_PATTERN = /^diff --git a\/(.+?) b\/(.+?)$/

        # Pattern to detect new file mode
        NEW_FILE_PATTERN = /^new file mode/

        # Pattern to detect deleted file mode
        DELETED_FILE_PATTERN = /^deleted file mode/

        # Parse a unified diff into individual file blocks
        #
        # @param diff_text [String, nil] The unified diff text to parse
        # @return [Array<Hash>] Array of file blocks, each with:
        #   - :path [String] - File path (uses 'b/' side)
        #   - :content [String] - Full diff content for this file
        #   - :lines [Integer] - Number of lines in the diff block
        #   - :change_type [Symbol] - :added, :deleted, or :modified
        #
        # @example
        #   DiffBoundaryFinder.parse(diff)
        #   #=> [{ path: "lib/foo.rb", content: "diff --git...", lines: 45, change_type: :modified }]
        def self.parse(diff_text)
          return [] if diff_text.nil? || diff_text.empty?

          blocks = []
          current_block = nil
          current_lines = []

          diff_text.each_line do |line|
            if (match = DIFF_HEADER_PATTERN.match(line))
              # Save the previous block if exists
              if current_block
                current_block[:content] = current_lines.join
                current_block[:lines] = current_lines.length
                blocks << current_block
              end

              # Start a new block
              current_block = {
                path: match[2],  # Use the 'b/' side (destination path)
                content: "",
                lines: 0,
                change_type: :modified  # Default, may be updated below
              }
              current_lines = [line]
            elsif current_block
              current_lines << line

              # Detect change type from mode lines
              if NEW_FILE_PATTERN.match?(line)
                current_block[:change_type] = :added
              elsif DELETED_FILE_PATTERN.match?(line)
                current_block[:change_type] = :deleted
              end
            end
          end

          # Don't forget the last block
          if current_block
            current_block[:content] = current_lines.join
            current_block[:lines] = current_lines.length
            blocks << current_block
          end

          blocks
        end

        # Parse and return just the file paths from a diff
        #
        # @param diff_text [String, nil] The unified diff text to parse
        # @return [Array<String>] List of file paths in the diff
        #
        # @example
        #   DiffBoundaryFinder.file_paths(diff)
        #   #=> ["lib/foo.rb", "test/foo_test.rb"]
        def self.file_paths(diff_text)
          parse(diff_text).map { |block| block[:path] }
        end

        # Count the number of files in a diff
        #
        # @param diff_text [String, nil] The unified diff text
        # @return [Integer] Number of files in the diff
        #
        # @example
        #   DiffBoundaryFinder.file_count(diff)
        #   #=> 5
        def self.file_count(diff_text)
          return 0 if diff_text.nil? || diff_text.empty?

          diff_text.scan(DIFF_HEADER_PATTERN).length
        end

        # Group file blocks by directory
        #
        # @param blocks [Array<Hash>] Array of file blocks from #parse
        # @return [Hash<String, Array<Hash>>] Files grouped by directory
        #
        # @example
        #   DiffBoundaryFinder.group_by_directory(blocks)
        #   #=> { "lib/atoms" => [...], "test/atoms" => [...] }
        def self.group_by_directory(blocks)
          blocks.group_by do |block|
            File.dirname(block[:path])
          end
        end
      end
    end
  end
end
