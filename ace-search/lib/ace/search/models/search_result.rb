# frozen_string_literal: true

module Ace
  module Search
    module Models
      # SearchResult represents a single search result item
      # This is a model - pure data structure with no behavior
      class SearchResult
        attr_reader :type, :path, :line_number, :content, :column,
          :match_start, :match_end, :submatches, :metadata

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

        def file?
          @type == :file
        end

        def match?
          @type == :match
        end

        def directory?
          @type == :directory
        end

        def basename
          File.basename(@path)
        end

        def dirname
          File.dirname(@path)
        end

        def extension
          ext = File.extname(@path)
          ext.empty? ? "" : ext[1..]
        end

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

        def to_json(*args)
          require "json"
          to_h.to_json(*args)
        end

        def self.file(path, metadata = {})
          new(type: :file, path: path, metadata: metadata)
        end

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

        def self.directory(path, metadata = {})
          new(type: :directory, path: path, metadata: metadata)
        end

        def ==(other)
          return false unless other.is_a?(SearchResult)

          @type == other.type &&
            @path == other.path &&
            @line_number == other.line_number &&
            @content == other.content &&
            @column == other.column
        end

        def hash
          [@type, @path, @line_number, @content, @column].hash
        end

        alias_method :eql?, :==
      end
    end
  end
end
