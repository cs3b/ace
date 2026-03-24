# frozen_string_literal: true

require_relative "../../atoms/token_estimator"
require_relative "../../atoms/diff_boundary_finder"

module Ace
  module Review
    module Molecules
      module Strategies
        # Chunked strategy - splits large diffs at file boundaries
        #
        # This strategy parses diffs into file blocks and groups them into
        # chunks that fit within the model's context window. It never splits
        # a file mid-diff, maintaining atomic file boundaries.
        #
        # Features:
        # - File-boundary chunking (never splits within a file)
        # - Summary header with changed files list (capped per file count)
        # - Overflow handling for files larger than context limit
        # - Metadata tracking for chunk index and totals
        #
        # @example Basic usage
        #   strategy = ChunkedStrategy.new(max_tokens_per_chunk: 100_000)
        #   if strategy.can_handle?(subject, 128_000)
        #     units = strategy.prepare(subject, context)
        #     # units = [
        #     #   { content: "Summary...\n\ndiff...", metadata: { strategy: :chunked, chunk_index: 0, ... } },
        #     #   { content: "Summary...\n\ndiff...", metadata: { strategy: :chunked, chunk_index: 1, ... } }
        #     # ]
        #   end
        class ChunkedStrategy
          # Default maximum tokens per chunk (leaving room for prompts/output)
          DEFAULT_MAX_TOKENS = 100_000

          # Reserve tokens for summary header
          SUMMARY_RESERVE_TOKENS = 2_000

          # File count thresholds for summary formatting
          SUMMARY_THRESHOLD_FULL = 20
          SUMMARY_THRESHOLD_GROUPED = 100

          # @param config [Hash] Strategy configuration
          # @option config [Integer] :max_tokens_per_chunk Maximum tokens per chunk
          # @option config [Boolean] :include_change_summary Include file summary (default: true)
          def initialize(config = {})
            # Normalize keys to symbols for consistent access (supports YAML string keys)
            @config = normalize_config_keys(config)
            @max_tokens_per_chunk = @config[:max_tokens_per_chunk] || DEFAULT_MAX_TOKENS
            @include_change_summary = @config.fetch(:include_change_summary, true)
          end

          # Check if this strategy can handle the given subject
          #
          # Returns true if the subject contains parseable diff blocks.
          # The chunked strategy can handle subjects of any size by splitting
          # them into multiple review units.
          #
          # @param subject [String] The review subject text (expected to be a diff)
          # @param model_context_limit [Integer] Model's token limit (used for reference)
          # @return [Boolean] true if subject contains valid diff format
          #
          # @example
          #   strategy.can_handle?("diff --git...", 128_000)  #=> true
          #   strategy.can_handle?("not a diff", 128_000)     #=> false
          def can_handle?(subject, model_context_limit)
            return false if subject.nil? || subject.empty?
            return false if model_context_limit.nil? || model_context_limit <= 0

            # Check if subject looks like a unified diff
            Atoms::DiffBoundaryFinder.file_count(subject) > 0
          end

          # Prepare the subject for review by splitting into chunks
          #
          # Parses the diff into file blocks and groups them into chunks
          # that fit within the configured token limit.
          #
          # @param subject [String] The review subject text (diff)
          # @param context [Hash] Review context
          # @option context [String] :system_prompt Base system prompt for the reviewer
          # @option context [String] :user_prompt User instructions or focus areas
          # @option context [String] :model Model identifier
          # @option context [Integer] :model_context_limit Token limit for the model
          # @option context [Hash] :preset Full preset configuration
          # @option context [Array<String>] :file_list List of files being reviewed
          # @return [Array<Hash>] Array of review units, each with :content and :metadata
          #
          # @example Return format
          #   [{
          #     content: "## Changes Summary\n...\n\ndiff --git...",
          #     metadata: {
          #       strategy: :chunked,
          #       chunk_index: 0,
          #       total_chunks: 2,
          #       files: ["lib/foo.rb", "lib/bar.rb"]
          #     }
          #   }, ...]
          def prepare(subject, context = {})
            return single_chunk_empty(subject) if subject.nil? || subject.empty?

            # Parse the diff into file blocks
            blocks = Atoms::DiffBoundaryFinder.parse(subject)
            return single_chunk_passthrough(subject) if blocks.empty?

            # Build the file summary once (used in all chunks)
            summary = @include_change_summary ? build_summary(blocks) : ""

            # Calculate available tokens per chunk (minus summary overhead)
            summary_tokens = Atoms::TokenEstimator.estimate(summary)
            available_tokens = @max_tokens_per_chunk - summary_tokens - SUMMARY_RESERVE_TOKENS

            # Guard against non-positive available tokens
            # If summary exceeds budget, use minimum of 1000 tokens to ensure some content
            minimum_available = 1_000
            available_tokens = [available_tokens, minimum_available].max

            # Group blocks into chunks
            chunks = build_chunks(blocks, available_tokens)

            # Format each chunk with summary and metadata
            total_chunks = chunks.length
            chunks.each_with_index.map do |chunk_blocks, index|
              build_review_unit(chunk_blocks, summary, index, total_chunks)
            end
          end

          # Strategy name for logging and debugging
          #
          # @return [Symbol] :chunked
          def strategy_name
            :chunked
          end

          private

          # Normalize config keys to symbols for consistent access
          #
          # @param config [Hash] Configuration with symbol or string keys
          # @return [Hash] Configuration with symbol keys
          def normalize_config_keys(config)
            return {} unless config.is_a?(Hash)
            config.transform_keys(&:to_sym)
          end

          # Build a summary of changed files
          #
          # @param blocks [Array<Hash>] File blocks from DiffBoundaryFinder
          # @return [String] Formatted summary
          def build_summary(blocks)
            file_count = blocks.length

            if file_count <= SUMMARY_THRESHOLD_FULL
              # List all files with change type
              build_full_summary(blocks)
            elsif file_count <= SUMMARY_THRESHOLD_GROUPED
              # Group by directory with counts
              build_grouped_summary(blocks)
            else
              # Directory-level totals only
              build_directory_summary(blocks)
            end
          end

          # Build full file list summary (<=20 files)
          #
          # @param blocks [Array<Hash>] File blocks
          # @return [String] Formatted summary
          def build_full_summary(blocks)
            lines = ["## Changes Summary", ""]
            lines << "**#{blocks.length} files changed:**"
            lines << ""

            blocks.each do |block|
              change_marker = change_type_marker(block[:change_type])
              lines << "- #{change_marker} `#{block[:path]}`"
            end

            lines.join("\n") + "\n"
          end

          # Build grouped summary (21-100 files)
          #
          # @param blocks [Array<Hash>] File blocks
          # @return [String] Formatted summary
          def build_grouped_summary(blocks)
            lines = ["## Changes Summary", ""]
            lines << "**#{blocks.length} files changed:**"
            lines << ""

            grouped = Atoms::DiffBoundaryFinder.group_by_directory(blocks)
            sorted_dirs = grouped.keys.sort

            sorted_dirs.each do |dir|
              dir_blocks = grouped[dir]
              counts = count_by_change_type(dir_blocks)
              dir_display = (dir == ".") ? "(root)" : "#{dir}/"

              parts = []
              parts << "#{counts[:modified]} modified" if counts[:modified] > 0
              parts << "#{counts[:added]} added" if counts[:added] > 0
              parts << "#{counts[:deleted]} deleted" if counts[:deleted] > 0

              lines << "- `#{dir_display}`: #{parts.join(", ")}"
            end

            lines.join("\n") + "\n"
          end

          # Build directory-level summary (>100 files)
          #
          # @param blocks [Array<Hash>] File blocks
          # @return [String] Formatted summary
          def build_directory_summary(blocks)
            lines = ["## Changes Summary", ""]

            counts = count_by_change_type(blocks)
            lines << "**#{blocks.length} files changed** (#{counts[:modified]} modified, #{counts[:added]} added, #{counts[:deleted]} deleted)"
            lines << ""

            grouped = Atoms::DiffBoundaryFinder.group_by_directory(blocks)
            sorted_dirs = grouped.keys.sort.take(20)

            lines << "Top directories:"
            sorted_dirs.each do |dir|
              dir_display = (dir == ".") ? "(root)" : "#{dir}/"
              lines << "- `#{dir_display}`: #{grouped[dir].length} files"
            end

            if grouped.keys.length > 20
              lines << "- ... and #{grouped.keys.length - 20} more directories"
            end

            lines.join("\n") + "\n"
          end

          # Get marker for change type
          #
          # @param change_type [Symbol] :added, :deleted, or :modified
          # @return [String] Marker string
          def change_type_marker(change_type)
            case change_type
            when :added then "[A]"
            when :deleted then "[D]"
            else "[M]"
            end
          end

          # Count blocks by change type
          #
          # @param blocks [Array<Hash>] File blocks
          # @return [Hash] Counts by type
          def count_by_change_type(blocks)
            counts = {added: 0, deleted: 0, modified: 0}
            blocks.each do |block|
              type = block[:change_type] || :modified
              counts[type] += 1
            end
            counts
          end

          # Group file blocks into chunks that fit within token limit
          #
          # @param blocks [Array<Hash>] File blocks from DiffBoundaryFinder
          # @param available_tokens [Integer] Available tokens per chunk
          # @return [Array<Array<Hash>>] Array of chunk arrays
          def build_chunks(blocks, available_tokens)
            chunks = []
            current_chunk = []
            current_tokens = 0

            blocks.each do |block|
              block_tokens = Atoms::TokenEstimator.estimate(block[:content])

              # Handle oversized single file
              if block_tokens > available_tokens
                # Finish current chunk if not empty
                chunks << current_chunk unless current_chunk.empty?
                current_chunk = []
                current_tokens = 0

                # Handle the oversized block
                chunks << [truncate_block(block, available_tokens)]
                next
              end

              # Check if block fits in current chunk
              if current_tokens + block_tokens <= available_tokens
                current_chunk << block
                current_tokens += block_tokens
              else
                # Start new chunk
                chunks << current_chunk unless current_chunk.empty?
                current_chunk = [block]
                current_tokens = block_tokens
              end
            end

            # Don't forget the last chunk
            chunks << current_chunk unless current_chunk.empty?

            chunks
          end

          # Truncate an oversized block to fit within token limit
          #
          # @param block [Hash] File block to truncate
          # @param available_tokens [Integer] Available tokens
          # @return [Hash] Truncated block with overflow metadata
          def truncate_block(block, available_tokens)
            content = block[:content]
            lines = content.lines

            # Reserve some tokens for the truncation marker
            marker_reserve = 50
            target_tokens = [available_tokens - marker_reserve, 0].max

            # Find the header boundary (everything before first @@ hunk marker)
            # This handles extended headers like renames, similarity index, etc.
            header_end = find_header_boundary(lines)

            # Find how many lines fit
            included_lines = []
            current_tokens = 0

            lines.each_with_index do |line, index|
              line_tokens = Atoms::TokenEstimator.estimate(line)

              # Always include header lines regardless of budget
              if index < header_end
                included_lines << line
                current_tokens += line_tokens
                next
              end

              break if current_tokens + line_tokens > target_tokens

              included_lines << line
              current_tokens += line_tokens
            end

            remaining_lines = lines.length - included_lines.length
            truncated_content = included_lines.join
            truncated_content += "\n[TRUNCATED: #{remaining_lines} lines omitted]\n"

            {
              path: block[:path],
              content: truncated_content,
              lines: included_lines.length,
              change_type: block[:change_type],
              overflow: true,
              truncated_lines: remaining_lines
            }
          end

          # Find the header boundary in a diff block (index of first content line after header)
          #
          # Searches for the first @@ hunk marker to determine where the header ends.
          # Handles extended headers like renames, similarity index, mode changes, etc.
          #
          # @param lines [Array<String>] Lines from the diff block
          # @return [Integer] Index of first line after header (minimum 4)
          def find_header_boundary(lines)
            # Default minimum: diff --git, index, ---, +++
            minimum_header = 4

            # Find the first @@ hunk marker
            lines.each_with_index do |line, index|
              return index if line.start_with?("@@")
            end

            # If no hunk marker found, use minimum header
            [minimum_header, lines.length].min
          end

          # Build a single review unit from chunk blocks
          #
          # @param chunk_blocks [Array<Hash>] File blocks in this chunk
          # @param summary [String] Summary header
          # @param index [Integer] Chunk index (0-based)
          # @param total [Integer] Total number of chunks
          # @return [Hash] Review unit with :content and :metadata
          def build_review_unit(chunk_blocks, summary, index, total)
            files = chunk_blocks.map { |b| b[:path] }
            has_overflow = chunk_blocks.any? { |b| b[:overflow] }

            # Build content
            content_parts = []
            content_parts << summary if @include_change_summary && !summary.empty?

            if total > 1
              content_parts << "---"
              content_parts << "**Chunk #{index + 1} of #{total}** (files: #{files.join(", ")})"
              content_parts << "---"
              content_parts << ""
            end

            chunk_blocks.each do |block|
              content_parts << block[:content]
            end

            # Build metadata
            metadata = {
              strategy: :chunked,
              chunk_index: index,
              total_chunks: total,
              files: files
            }

            # Add overflow information if present
            if has_overflow
              metadata[:overflow] = true
              overflow_info = chunk_blocks.select { |b| b[:overflow] }.map do |b|
                {path: b[:path], truncated_lines: b[:truncated_lines]}
              end
              metadata[:overflow_files] = overflow_info
            end

            {
              content: content_parts.join("\n"),
              metadata: metadata
            }
          end

          # Create a single chunk for empty subject
          #
          # @param subject [String] The empty/nil subject
          # @return [Array<Hash>] Single review unit
          def single_chunk_empty(subject)
            [{
              content: subject.to_s,
              metadata: {
                strategy: :chunked,
                chunk_index: 0,
                total_chunks: 1,
                files: []
              }
            }]
          end

          # Create a single chunk passthrough (when no diff structure found)
          #
          # @param subject [String] The subject text
          # @return [Array<Hash>] Single review unit
          def single_chunk_passthrough(subject)
            [{
              content: subject,
              metadata: {
                strategy: :chunked,
                chunk_index: 0,
                total_chunks: 1,
                files: []
              }
            }]
          end
        end
      end
    end
  end
end
