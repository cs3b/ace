# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Matches file paths against glob patterns with specificity scoring
      # Used for determining which validator group applies to a file
      class PatternMatcher
        # Score a pattern based on specificity (higher = more specific)
        # @param pattern [String] Glob pattern to score
        # @return [Integer] Specificity score
        def self.specificity(pattern)
          return 0 if pattern.nil? || pattern.empty?

          score = 0

          # Exact filename match (no glob chars) gets highest score
          unless pattern.include?('*') || pattern.include?('?') || pattern.include?('[')
            return 1000 + pattern.length
          end

          # Directory depth: +100 per path segment
          score += pattern.count('/') * 100

          # Double-star penalty: -50 per **
          score -= pattern.scan('**').count * 50

          # Single-star bonus: +10 per * (but not **)
          single_stars = pattern.gsub('**', '').count('*')
          score += single_stars * 10

          # Literal prefix length: +1 per char before first glob
          literal_prefix = pattern.split(/[\*\?\[]/).first || ''
          score += literal_prefix.length

          score
        end

        # Check if a path matches a pattern
        # @param path [String] File path to check
        # @param pattern [String] Glob pattern
        # @return [Boolean] True if path matches pattern
        def self.matches?(path, pattern)
          return false if path.nil? || pattern.nil?

          # Normalize path (remove leading ./)
          normalized_path = path.sub(%r{^\./}, '')

          # File.fnmatch with FNM_PATHNAME for proper ** handling
          # FNM_EXTGLOB for brace expansion {rb,rake}
          File.fnmatch(pattern, normalized_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) ||
            File.fnmatch(pattern, File.basename(normalized_path), File::FNM_PATHNAME | File::FNM_EXTGLOB)
        end

        # Find the best matching pattern for a path
        # @param path [String] File path to match
        # @param patterns [Array<String>] List of patterns to check
        # @return [String, nil] Best matching pattern or nil if no match
        def self.best_match(path, patterns)
          return nil if patterns.nil? || patterns.empty?

          matching = patterns.select { |p| matches?(path, p) }
          return nil if matching.empty?

          # Return pattern with highest specificity
          matching.max_by { |p| specificity(p) }
        end

        # Find the best matching group for a path
        # @param path [String] File path to match
        # @param groups [Hash] Group name => { patterns: [...], ... }
        # @return [Array<Symbol, Hash>, nil] [group_name, group_config] or nil
        def self.best_group_match(path, groups)
          return nil if groups.nil? || groups.empty?

          best_group = nil
          best_score = -Float::INFINITY

          groups.each do |name, config|
            patterns = config[:patterns] || config['patterns'] || []
            pattern = best_match(path, patterns)
            next unless pattern

            score = specificity(pattern)
            if score > best_score
              best_score = score
              best_group = [name.to_sym, config]
            end
          end

          best_group
        end
      end
    end
  end
end
