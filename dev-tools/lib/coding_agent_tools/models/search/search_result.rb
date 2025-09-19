# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Search
      # SearchResult represents a single search result item
      # This is a model - pure data structure with no behavior
      class SearchResult
        attr_reader :type, :path, :line_number, :content, :column,
          :match_start, :match_end, :submatches, :metadata

        # @param type [Symbol] Type of result (:file, :match, :directory)
        # @param path [String] File or directory path
        # @param line_number [Integer, nil] Line number for content matches
        # @param content [String, nil] Line content for content matches
        # @param column [Integer, nil] Column number for content matches
        # @param match_start [Integer, nil] Start position of match in line
        # @param match_end [Integer, nil] End position of match in line
        # @param submatches [Array, nil] Array of submatch information
        # @param metadata [Hash] Additional metadata (size, modified_time, etc.)
        def initialize(type:, path:, line_number: nil, content: nil, column: nil,
          match_start: nil, match_end: nil, submatches: nil, metadata: {})
          @type = type
          @path = path
          @line_number = line_number
          @content = content
          @column = column
          @match_start = match_start
          @match_end = match_end
          @submatches = submatches || []
          @metadata = metadata || {}
        end

        # Check if this is a file result
        # @return [Boolean] True if this represents a file
        def file?
          @type == :file
        end

        # Check if this is a content match result
        # @return [Boolean] True if this represents a content match
        def match?
          @type == :match
        end

        # Check if this is a directory result
        # @return [Boolean] True if this represents a directory
        def directory?
          @type == :directory
        end

        # Get the file basename
        # @return [String] File basename
        def basename
          File.basename(@path)
        end

        # Get the file directory
        # @return [String] Directory containing the file
        def dirname
          File.dirname(@path)
        end

        # Get the file extension
        # @return [String] File extension without the dot
        def extension
          ext = File.extname(@path)
          ext.empty? ? "" : ext[1..]
        end

        # Get repository name from metadata
        # @return [String, nil] Repository name if available
        def repository
          @metadata[:repository]
        end

        # Get file size from metadata
        # @return [Integer, nil] File size in bytes if available
        def size
          @metadata[:size]
        end

        # Get file modified time from metadata
        # @return [Time, nil] File modification time if available
        def modified_time
          @metadata[:modified_time]
        end

        # Check if file is readable
        # @return [Boolean, nil] True if readable, nil if unknown
        def readable?
          @metadata[:readable]
        end

        # Convert to hash representation
        # @return [Hash] Hash representation of the result
        def to_h
          {
            type: @type,
            path: @path,
            line_number: @line_number,
            content: @content,
            column: @column,
            match_start: @match_start,
            match_end: @match_end,
            submatches: @submatches,
            metadata: @metadata
          }
        end

        # Convert to JSON representation
        # @return [String] JSON string representation
        def to_json(*args)
          require "json"
          to_h.to_json(*args)
        end

        # Create a file result
        # @param path [String] File path
        # @param metadata [Hash] Additional metadata
        # @return [SearchResult] New file result
        def self.file(path, metadata = {})
          new(type: :file, path: path, metadata: metadata)
        end

        # Create a content match result
        # @param path [String] File path
        # @param line_number [Integer] Line number
        # @param content [String] Line content
        # @param options [Hash] Additional options (column, match positions, etc.)
        # @return [SearchResult] New match result
        def self.match(path, line_number, content, options = {})
          new(
            type: :match,
            path: path,
            line_number: line_number,
            content: content,
            column: options[:column],
            match_start: options[:match_start],
            match_end: options[:match_end],
            submatches: options[:submatches],
            metadata: options[:metadata] || {}
          )
        end

        # Create a directory result
        # @param path [String] Directory path
        # @param metadata [Hash] Additional metadata
        # @return [SearchResult] New directory result
        def self.directory(path, metadata = {})
          new(type: :directory, path: path, metadata: metadata)
        end

        # Equality comparison
        # @param other [SearchResult] Other result to compare
        # @return [Boolean] True if results are equal
        def ==(other)
          return false unless other.is_a?(SearchResult)

          @type == other.type &&
            @path == other.path &&
            @line_number == other.line_number &&
            @content == other.content &&
            @column == other.column &&
            @match_start == other.match_start &&
            @match_end == other.match_end &&
            @submatches == other.submatches &&
            @metadata == other.metadata
        end

        # Hash code for use in collections
        # @return [Integer] Hash code
        def hash
          [@type, @path, @line_number, @content, @column, @match_start, @match_end].hash
        end

        alias_method :eql?, :==
      end
    end
  end
end
