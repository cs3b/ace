# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for pattern matching and filtering
      # Migrated from ace-git-diff
      module PatternFilter
        # Maximum cache size to prevent unbounded memory growth in long-running processes
        MAX_CACHE_SIZE = 100

        # Cache for compiled regex patterns (performance optimization)
        # Key: sorted pattern array joined by "|", Value: Array of compiled Regexp
        # Uses FIFO eviction: oldest inserted entry removed when cache exceeds MAX_CACHE_SIZE
        # Note: Ruby hashes preserve insertion order, so shift removes the oldest entry
        @pattern_cache = {}
        @cache_mutex = Mutex.new

        class << self
          # Convert glob patterns to regex patterns
          # Uses caching for performance when same patterns are used repeatedly
          # @param glob_patterns [Array<String>] Glob patterns like "test/**/*"
          # @return [Array<Regexp>] Regex patterns for matching
          def glob_to_regex(glob_patterns)
            return [] if glob_patterns.nil? || glob_patterns.empty?

            # Generate cache key from sorted patterns
            cache_key = glob_patterns.sort.join("|")

            # Check cache first (thread-safe read)
            PatternFilter.instance_variable_get(:@cache_mutex).synchronize do
              cache = PatternFilter.instance_variable_get(:@pattern_cache)
              return cache[cache_key] if cache.key?(cache_key)

              # Evict oldest entry if cache is full (FIFO eviction)
              cache.shift if cache.size >= MAX_CACHE_SIZE

              # Compile patterns and cache
              patterns = glob_patterns.map { |pattern| compile_glob_pattern(pattern) }
              cache[cache_key] = patterns
              patterns
            end
          end

          # Clear the pattern cache (mainly for testing)
          def clear_cache!
            PatternFilter.instance_variable_get(:@cache_mutex).synchronize do
              PatternFilter.instance_variable_get(:@pattern_cache).clear
            end
          end

          # Check if a file path should be excluded based on patterns
          # @param file_path [String] Path to check
          # @param patterns [Array<Regexp>] Regex patterns to match against
          # @return [Boolean] True if path matches any exclude pattern
          def should_exclude?(file_path, patterns)
            return false if file_path.nil? || file_path.empty?
            return false if patterns.nil? || patterns.empty?

            patterns.any? { |pattern| file_path.match?(pattern) }
          end

          # Check if a line is a file header in git diff format
          # @param line [String] Line to check
          # @return [Boolean] True if line is a file header
          def file_header?(line)
            return false if line.nil? || line.empty?

            line.start_with?("diff --git", "+++", "---") ||
              line.match?(/^index [a-f0-9]+\.\.[a-f0-9]+/)
          end

          # Extract file path from diff header line
          # @param line [String] Diff header line
          # @return [String] Extracted file path or empty string
          def extract_file_path(line)
            return "" if line.nil? || line.empty?

            case line
            when /^diff --git a\/(.+) b\/(.+)$/
              Regexp.last_match(2) # Use the 'b/' path (new file path)
            when /^\+\+\+ b\/(.+)$/
              Regexp.last_match(1)
            when /^--- a\/(.+)$/
              Regexp.last_match(1)
            else
              ""
            end
          end

          # Filter paths from diff output based on exclude patterns
          # @param diff [String] The diff content
          # @param exclude_patterns [Array<Regexp>] Patterns to exclude
          # @return [String] Filtered diff content
          def filter_diff_by_patterns(diff, exclude_patterns)
            return "" if diff.nil? || diff.empty?
            return diff if exclude_patterns.nil? || exclude_patterns.empty?

            lines = diff.split("\n")
            filtered_lines = []
            skip_until_next_file = false

            lines.each do |line|
              # Check if this is a file header
              if file_header?(line)
                file_path = extract_file_path(line)
                if should_exclude?(file_path, exclude_patterns)
                  skip_until_next_file = true
                else
                  skip_until_next_file = false
                  filtered_lines << line
                end
              elsif !skip_until_next_file
                filtered_lines << line
              end
            end

            filtered_lines.join("\n")
          end

          # Match a path against include patterns (glob)
          # @param file_path [String] Path to check
          # @param include_patterns [Array<String>] Glob patterns to include
          # @return [Boolean] True if path matches any include pattern
          def matches_include?(file_path, include_patterns)
            return true if include_patterns.nil? || include_patterns.empty?
            return false if file_path.nil? || file_path.empty?

            regex_patterns = glob_to_regex(include_patterns)
            regex_patterns.any? { |pattern| file_path.match?(pattern) }
          end

          private

          # Compile a single glob pattern to regex
          # @param pattern [String] Glob pattern
          # @return [Regexp] Compiled regex
          def compile_glob_pattern(pattern)
            # Escape special regex characters except glob wildcards
            regex_str = Regexp.escape(pattern)

            # Convert escaped glob patterns to regex
            regex_str = regex_str
              .gsub('\\*\\*/', ".*")     # **/ → .* (zero or more segments)
              .gsub('\\*\\*', ".*")       # ** → .* (zero or more segments)
              .gsub('\\*', "[^/]*")       # * → [^/]* (within segment)
              .gsub('\\?', ".")           # ? → . (single char)

            # Anchor to start of path
            Regexp.new("^#{regex_str}")
          end
        end
      end
    end
  end
end
