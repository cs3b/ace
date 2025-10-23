# frozen_string_literal: true

module Ace
  module GitDiff
    module Models
      # Data structure representing diff configuration
      class DiffConfig
        attr_reader :exclude_patterns, :exclude_whitespace, :exclude_renames,
                    :exclude_moves, :max_lines, :ranges, :paths, :since, :format

        # @param exclude_patterns [Array<String>] Glob patterns to exclude
        # @param exclude_whitespace [Boolean] Whether to exclude whitespace changes
        # @param exclude_renames [Boolean] Whether to exclude renames
        # @param exclude_moves [Boolean] Whether to exclude moves
        # @param max_lines [Integer] Maximum lines in diff output
        # @param ranges [Array<String>] Git ranges to diff (e.g., ["origin/main...HEAD"])
        # @param paths [Array<String>] Path patterns to include
        # @param since [String] Date or commit to diff from
        # @param format [Symbol] Output format (:diff or :summary)
        def initialize(
          exclude_patterns: [],
          exclude_whitespace: true,
          exclude_renames: false,
          exclude_moves: false,
          max_lines: 10_000,
          ranges: [],
          paths: [],
          since: nil,
          format: :diff
        )
          @exclude_patterns = Array(exclude_patterns)
          @exclude_whitespace = exclude_whitespace
          @exclude_renames = exclude_renames
          @exclude_moves = exclude_moves
          @max_lines = max_lines
          @ranges = Array(ranges)
          @paths = Array(paths)
          @since = since
          @format = format&.to_sym || :diff
        end

        # Check if diff should exclude whitespace changes
        # @return [Boolean] True if whitespace should be excluded
        def exclude_whitespace?
          @exclude_whitespace
        end

        # Check if diff should exclude renames
        # @return [Boolean] True if renames should be excluded
        def exclude_renames?
          @exclude_renames
        end

        # Check if diff should exclude moves
        # @return [Boolean] True if moves should be excluded
        def exclude_moves?
          @exclude_moves
        end

        # Get git diff command flags based on configuration
        # @return [Array<String>] Command flags
        def git_flags
          flags = []
          flags << "-w" if exclude_whitespace?
          flags << "--no-renames" if exclude_renames?
          flags << "--diff-filter=ACMTUXB" unless exclude_renames? # Exclude R (renames) if flag set
          flags
        end

        # Convert to hash representation
        # @return [Hash] Hash representation of the config
        def to_h
          {
            exclude_patterns: exclude_patterns,
            exclude_whitespace: exclude_whitespace?,
            exclude_renames: exclude_renames?,
            exclude_moves: exclude_moves?,
            max_lines: max_lines,
            ranges: ranges,
            paths: paths,
            since: since,
            format: format
          }
        end

        # Create DiffConfig from hash (e.g., from YAML config)
        # @param hash [Hash] Configuration hash
        # @return [DiffConfig] New DiffConfig instance
        def self.from_hash(hash)
          return new if hash.nil? || hash.empty?

          new(
            exclude_patterns: hash["exclude_patterns"] || hash[:exclude_patterns] || [],
            exclude_whitespace: hash.fetch("exclude_whitespace", hash.fetch(:exclude_whitespace, true)),
            exclude_renames: hash.fetch("exclude_renames", hash.fetch(:exclude_renames, false)),
            exclude_moves: hash.fetch("exclude_moves", hash.fetch(:exclude_moves, false)),
            max_lines: hash.fetch("max_lines", hash.fetch(:max_lines, 10_000)),
            ranges: hash["ranges"] || hash[:ranges] || [],
            paths: hash["paths"] || hash[:paths] || [],
            since: hash["since"] || hash[:since],
            format: hash["format"] || hash[:format] || :diff
          )
        end

        # Merge with another config (other takes precedence - complete override)
        # @param other [DiffConfig, Hash] Other config to merge
        # @return [DiffConfig] New merged DiffConfig
        def merge(other)
          other_hash = other.is_a?(DiffConfig) ? other.to_h : other

          self.class.from_hash(to_h.merge(other_hash))
        end
      end
    end
  end
end
