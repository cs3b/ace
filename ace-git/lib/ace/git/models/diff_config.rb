# frozen_string_literal: true

module Ace
  module Git
    module Models
      # Data structure representing diff configuration
      # Migrated from ace-git-diff
      class DiffConfig
        attr_reader :exclude_patterns, :exclude_whitespace, :exclude_renames,
          :exclude_moves, :max_lines, :ranges, :paths, :since, :format, :timeout,
          :grouped_stats_layers, :grouped_stats_collapse_above,
          :grouped_stats_show_full_tree, :grouped_stats_dotfile_groups

        # @param exclude_patterns [Array<String>] Glob patterns to exclude
        # @param exclude_whitespace [Boolean] Whether to exclude whitespace changes
        # @param exclude_renames [Boolean] Whether to exclude renames
        # @param exclude_moves [Boolean] Whether to exclude moves
        # @param max_lines [Integer] Maximum lines in diff output
        # @param ranges [Array<String>] Git ranges to diff (e.g., ["origin/main...HEAD"])
        # @param paths [Array<String>] Path patterns to include
        # @param since [String] Date or commit to diff from
        # @param format [Symbol] Output format (:diff or :summary)
        # @param timeout [Integer] Command timeout in seconds (default from config)
        # @param grouped_stats_layers [Array<String>] Layer order for grouped-stats output
        # @param grouped_stats_collapse_above [Integer] Markdown collapse threshold
        # @param grouped_stats_show_full_tree [String] Tree rendering mode
        # @param grouped_stats_dotfile_groups [Array<String>] Dot directories to prioritize
        def initialize(
          exclude_patterns: [],
          exclude_whitespace: true,
          exclude_renames: false,
          exclude_moves: false,
          max_lines: 10_000,
          ranges: [],
          paths: [],
          since: nil,
          format: :diff,
          timeout: Ace::Git.git_timeout,
          grouped_stats_layers: %w[lib test handbook],
          grouped_stats_collapse_above: 5,
          grouped_stats_show_full_tree: "collapsible",
          grouped_stats_dotfile_groups: %w[.ace-task .ace]
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
          @timeout = timeout || Ace::Git.git_timeout
          @grouped_stats_layers = Array(grouped_stats_layers).map(&:to_s)
          @grouped_stats_collapse_above = grouped_stats_collapse_above.to_i
          @grouped_stats_show_full_tree = grouped_stats_show_full_tree.to_s
          @grouped_stats_dotfile_groups = Array(grouped_stats_dotfile_groups).map(&:to_s)
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
          # Use --diff-filter to exclude renames (R) and optionally moves
          # This is more explicit and avoids redundant flags
          # ACDMTUXB includes: Added, Copied, Deleted, Modified, Type, Unmerged, Unknown, Broken
          # When excluding moves, we also disable copy detection (C) as moves are detected as copy+delete
          if exclude_renames? && exclude_moves?
            # Exclude both renames (R) and copies (C) which covers moves
            flags << "--diff-filter=ADMTUXB"
            flags << "-M0" # Disable rename detection entirely
          elsif exclude_renames?
            flags << "--diff-filter=ACDMTUXB"
          elsif exclude_moves?
            # Moves appear as rename with 100% similarity, disable high-similarity renames
            flags << "-M0" # Disable rename detection (moves are renames at 100% similarity)
          end
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
            format: format,
            timeout: timeout,
            grouped_stats: {
              layers: grouped_stats_layers,
              collapse_above: grouped_stats_collapse_above,
              show_full_tree: grouped_stats_show_full_tree,
              dotfile_groups: grouped_stats_dotfile_groups
            }
          }
        end

        # Known configuration keys
        KNOWN_KEYS = %w[
          exclude_patterns exclude_whitespace exclude_renames exclude_moves
          max_lines ranges paths since format timeout grouped_stats
        ].freeze

        # Create DiffConfig from hash (e.g., from YAML config)
        # Warns on unknown keys to help users catch typos
        # @param hash [Hash] Configuration hash
        # @return [DiffConfig] New DiffConfig instance
        def self.from_hash(hash)
          return new if hash.nil? || hash.empty?

          # Warn about unknown keys to help catch typos
          warn_unknown_keys(hash)

          grouped_stats = hash["grouped_stats"] || hash[:grouped_stats] || {}

          new(
            exclude_patterns: hash["exclude_patterns"] || hash[:exclude_patterns] || [],
            exclude_whitespace: hash.fetch("exclude_whitespace", hash.fetch(:exclude_whitespace, true)),
            exclude_renames: hash.fetch("exclude_renames", hash.fetch(:exclude_renames, false)),
            exclude_moves: hash.fetch("exclude_moves", hash.fetch(:exclude_moves, false)),
            max_lines: hash.fetch("max_lines", hash.fetch(:max_lines, 10_000)),
            ranges: hash["ranges"] || hash[:ranges] || [],
            paths: hash["paths"] || hash[:paths] || [],
            since: hash["since"] || hash[:since],
            format: hash["format"] || hash[:format] || :diff,
            timeout: hash.fetch("timeout", hash.fetch(:timeout, Ace::Git.git_timeout)),
            grouped_stats_layers: grouped_stats["layers"] || grouped_stats[:layers] || %w[lib test handbook],
            grouped_stats_collapse_above: grouped_stats.fetch("collapse_above", grouped_stats.fetch(:collapse_above, 5)),
            grouped_stats_show_full_tree: grouped_stats["show_full_tree"] || grouped_stats[:show_full_tree] || "collapsible",
            grouped_stats_dotfile_groups: grouped_stats["dotfile_groups"] || grouped_stats[:dotfile_groups] || %w[.ace-task .ace]
          )
        end

        # Warn about unknown configuration keys
        # @param hash [Hash] Configuration hash
        def self.warn_unknown_keys(hash)
          return if hash.nil? || hash.empty?

          hash.each_key do |key|
            key_str = key.to_s
            next if KNOWN_KEYS.include?(key_str)
            # Skip nested sections that may be passed through
            next if %w[diff rebase pr squash default_branch remote verbose].include?(key_str)

            warn "[ace-git] Unknown config key '#{key_str}' in DiffConfig - did you mean one of: #{KNOWN_KEYS.join(", ")}?"
          end
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
