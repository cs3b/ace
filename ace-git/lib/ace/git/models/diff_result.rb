# frozen_string_literal: true

module Ace
  module Git
    module Models
      # Data structure representing the result of a diff operation
      # Migrated from ace-git-diff
      class DiffResult
        attr_reader :content, :stats, :files, :metadata, :filtered

        # @param content [String] The diff content
        # @param stats [Hash] Statistics about the diff (additions, deletions, files)
        # @param files [Array<String>] List of files in the diff
        # @param metadata [Hash] Additional metadata (range, since, options, etc)
        # @param filtered [Boolean] Whether the diff has been filtered
        def initialize(content:, stats:, files:, metadata: {}, filtered: false)
          @content = content
          @stats = stats
          @files = files
          @metadata = metadata
          @filtered = filtered
        end

        # Check if the diff is empty
        # @return [Boolean] True if diff has no content
        def empty?
          content.nil? || content.strip.empty?
        end

        # Check if the diff has changes
        # @return [Boolean] True if diff contains additions or deletions
        def has_changes?
          stats[:total_changes].to_i > 0
        end

        # Get the number of lines in the diff
        # @return [Integer] Line count
        def line_count
          stats[:line_count] || content&.count("\n")&.+(1) || 0
        end

        # Get human-readable summary
        # @return [String] Summary string
        def summary
          "#{files.length} files, +#{stats[:additions]} -#{stats[:deletions]}"
        end

        # Convert to hash representation
        # @return [Hash] Hash representation of the diff result
        def to_h
          {
            content: content,
            stats: stats,
            files: files,
            metadata: metadata,
            filtered: filtered,
            empty: empty?,
            has_changes: has_changes?,
            line_count: line_count,
            summary: summary
          }
        end

        # Create a DiffResult from parsed diff data
        # @param parsed_data [Hash] Parsed diff data from DiffParser
        # @param metadata [Hash] Additional metadata
        # @param filtered [Boolean] Whether the diff was filtered
        # @return [DiffResult] New DiffResult instance
        def self.from_parsed(parsed_data, metadata: {}, filtered: false)
          new(
            content: parsed_data[:content],
            stats: parsed_data[:stats].merge(line_count: parsed_data[:line_count]),
            files: parsed_data[:files],
            metadata: metadata,
            filtered: filtered
          )
        end

        # Create an empty DiffResult
        # @param metadata [Hash] Optional metadata
        # @return [DiffResult] Empty DiffResult instance
        def self.empty(metadata: {})
          new(
            content: "",
            stats: {additions: 0, deletions: 0, files: 0, total_changes: 0, line_count: 0},
            files: [],
            metadata: metadata,
            filtered: false
          )
        end
      end
    end
  end
end
