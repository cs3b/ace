# frozen_string_literal: true

require_relative "subject_filter"

module Ace
  module Review
    module Molecules
      # Review-exempt paths: globs whose deltas never require a model report.
      #
      # A delta round whose changed files all match the declared patterns is
      # recorded as a no-op session without any model call; in mixed rounds the
      # exempt paths are excluded from the subject and enumerated. Patterns are
      # validated at config load — a pattern that matches every path is refused
      # instead of silently exempting the world.
      module ExemptPaths
        # Probe set covering root-level and nested paths. A pattern matching
        # every probe leaves nothing reviewable by definition. Dotfiles are
        # excluded: wildcard patterns never match them under fnmatch pathname
        # semantics (no FNM_DOTMATCH), so they cannot prove over-breadth.
        OVER_BROAD_PROBES = ["README.md", "a.txt", "dir/b.txt", "a/b/c.txt"].freeze

        # Conventional spellings authors use for "everything". fnmatch pathname
        # semantics make bare "*" / "**" single-segment, but their intent is
        # unmistakable — refuse them instead of silently exempting the world.
        CONVENTIONAL_MATCH_ALL = ["*", "**"].freeze

        # @param patterns [Object] raw exempt_paths config value
        # @return [String, nil] refusal message, or nil when valid
        def self.validate!(patterns)
          return nil if patterns.nil?

          unless patterns.is_a?(Array) && patterns.all? { |pattern| pattern.is_a?(String) && !pattern.strip.empty? }
            return "exempt_paths must be a list of non-empty glob strings"
          end

          patterns.each do |pattern|
            if CONVENTIONAL_MATCH_ALL.include?(pattern) ||
                OVER_BROAD_PROBES.all? { |probe| SubjectFilter.glob_match?(pattern, probe) }
              return "exempt_paths pattern '#{pattern}' matches every path; refusing to exempt the world"
            end
          end
          nil
        end

        # Partition changed paths (destination paths, as in the diff manifest)
        # into exempt and non-exempt.
        #
        # @param paths [Array<String>]
        # @param patterns [Array<String>, nil]
        # @return [Hash] {exempt:, non_exempt:}
        def self.classify(paths, patterns)
          patterns = Array(patterns)
          exempt, non_exempt = Array(paths).partition do |path|
            patterns.any? { |pattern| SubjectFilter.glob_match?(pattern, path) }
          end
          {exempt: exempt, non_exempt: non_exempt}
        end
      end
    end
  end
end
